class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def show
    @event_date = params[:id]
    # Fetch event for display
    year = Time.now.year
    api_key = ENV["RAPIDAPI_KEY"]
    response = nil
    if api_key.present?
      response = HTTParty.get(
        "https://holidays-by-api-ninjas.p.rapidapi.com/v1/holidays",
        query: { country: "us", year: year },
        headers: {
          "x-rapidapi-key" => api_key,
          "x-rapidapi-host" => "holidays-by-api-ninjas.p.rapidapi.com"
        }
      )
    else
      Rails.logger.warn("RAPIDAPI_KEY missing; cannot fetch external events")
    end
    parsed = JSON.parse(response.body) rescue []
    holidays = parsed.is_a?(Array) ? parsed : (parsed["holidays"] || [])
    @event = holidays.find do |h|
      # Ensure we are working with a hash-like item
      h.is_a?(Hash) && h["date"].to_s == @event_date.to_s
    end
    if @event.nil?
      redirect_to root_path, alert: "Event not found"
    end
  end

  # GET /checkout/simulate
  def simulate
    @cart = sanitize_cart(session[:cart] || {})
    if @cart.blank?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end
    @items = Event.where(id: @cart.keys).map do |event|
      { event: event, quantity: @cart[event.id.to_s].to_i }
    end
    @total = @items.sum { |i| i[:event].price * i[:quantity] }
  end

  # POST /checkout/simple
  # Demonstration flow: compute totals and go to confirmation without payment or inventory updates
  def simple
    cart = sanitize_cart(session[:cart] || {})
    if cart.blank?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    events = Event.where(id: cart.keys).select(:id, :name, :price)
    if events.empty?
      redirect_to cart_path, alert: "No valid items in cart." and return
    end

    total_qty = 0
    total_paid = 0
    events.each do |ev|
      qty = cart[ev.id.to_s].to_i
      next if qty <= 0
      total_qty += qty
      total_paid += ev.price.to_f * qty
    end

    if total_qty <= 0 || total_paid <= 0
      redirect_to cart_path, alert: "No payable items in cart." and return
    end

    session[:last_purchase_items] = total_qty
    session[:last_purchase_total] = total_paid
    # No DB purchases created in simple flow; clear any previous recent IDs
    session[:recent_purchase_ids] = []
    session[:cart] = {}

    redirect_to confirmation_path, notice: "Checkout simulated successfully. No payment was processed."
  rescue => e
    Rails.logger.error("Simple checkout error: #{e.message}")
    redirect_to cart_path, alert: "Unable to simulate checkout. Please try again."
  end

  # POST /checkout/create_session
  def create_session
    unless ENV["STRIPE_SECRET_KEY"].present?
      Rails.logger.error("Stripe secret key missing (ENV STRIPE_SECRET_KEY)")
      redirect_to checkout_simulate_path, notice: "Simulation mode: Stripe not configured. Proceed with a simulated payment." and return
    end

    cart = sanitize_cart(session[:cart] || {})
    if cart.blank?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    # Only consider items with a positive quantity to reduce work/IO
    payable_ids = cart.select { |_id, q| q.to_i > 0 }.keys
    if payable_ids.empty?
      redirect_to cart_path, alert: "No payable items in cart (invalid quantity)." and return
    end

    # Select only the columns we need for Stripe line items
    items = Event.where(id: payable_ids).select(:id, :name, :price)
    if items.empty?
      Rails.logger.warn("Checkout attempted with invalid cart keys: #{cart.keys.inspect}")
      redirect_to cart_path, alert: "No valid items in cart." and return
    end

    line_items = []
    items.each do |event|
      qty = cart[event.id.to_s].to_i
      next if qty <= 0
      unit_amount = (event.price.to_f * 100).to_i
      if unit_amount <= 0
        Rails.logger.warn("Skipping zero/invalid price event id=#{event.id} price=#{event.price}")
        next
      end
      line_items << {
        price_data: {
          currency: "usd",
          product_data: { name: event.name },
          unit_amount: unit_amount
        },
        quantity: qty
      }
    end

    if line_items.blank?
      redirect_to cart_path, alert: "No payable items in cart (invalid quantity or price)." and return
    end

    session_obj = Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: line_items,
      success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cart_url,
      customer_email: current_user.email
    )

    redirect_to session_obj.url, allow_other_host: true
  rescue => e
    Rails.logger.error("Stripe create_session error: #{e.message}")
    redirect_to cart_path, alert: "Unable to start checkout. Please try again."
  end

  # GET /checkout/success
  def complete
    # Optionally verify session: Stripe::Checkout::Session.retrieve(params[:session_id])
    cart = sanitize_cart(session[:cart] || {})
    if cart.blank?
      redirect_to confirmation_path, notice: "Payment completed." and return
    end

    purchased_items = []
    total_paid = 0

    ActiveRecord::Base.transaction do
      # Work only with payable items and lock them in a single query to avoid N+1
      payable_ids = cart.select { |_id, q| q.to_i > 0 }.keys
      events = Event.where(id: payable_ids).lock('FOR UPDATE').select(:id, :name, :price, :tickets_available)

        quantity = cart[ev.id.to_s].to_i
        next if quantity <= 0

        if ev.tickets_available >= quantity
          ev.update!(tickets_available: ev.tickets_available - quantity)
           current_user.purchases.create!(
             event: ev,
             quantity: quantity,
             total_price: ev.price * quantity,
             ticket_type: (session[:ticket_types] || {})[ev.id.to_s].presence || 'Adult',
             purchased_at: Time.current
           )
          purchased_items << { id: ev.id, name: ev.name, quantity: quantity, price: ev.price }
          total_paid += ev.price * quantity
        else
          raise ActiveRecord::Rollback, "Not enough tickets available for #{ev.name}"
        end

    end

    if purchased_items.any?
      session[:last_purchase_items] = purchased_items.sum { |i| i[:quantity] }
      session[:last_purchase_total] = total_paid
      # Capture the exact purchases created in this transaction
      recent_ids = current_user.purchases.order(purchased_at: :desc).limit(purchased_items.size).pluck(:id)
      session[:recent_purchase_ids] = recent_ids
      session[:cart] = {}
      # Kick off email in background
      TicketEmailJob.perform_later(current_user.id)
      redirect_to confirmation_path, notice: "Payment successful! Your tickets will be emailed shortly."
    else
      redirect_to cart_path, alert: "Could not finalize purchase."
    end
  rescue => e
    Rails.logger.error("Checkout complete error: #{e.message}")
    redirect_to cart_path, alert: "There was an issue finalizing your purchase."
  end

  private

  # Sanitize the cart structure to prevent unexpected inputs
  # Returns a Hash with stringified numeric IDs => positive integer quantities
  def sanitize_cart(cart)
    return {} unless cart.is_a?(Hash)
    cleaned = {}
    cart.each do |id, qty|
      # accept only numeric IDs
      id_str = id.to_s
      next unless id_str.match?(/^\d+$/)
      q = qty.to_i
      next if q <= 0
      cleaned[id_str] = q
    end
    cleaned
  end
end