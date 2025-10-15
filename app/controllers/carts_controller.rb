class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = session[:cart] || {}
    @events = Event.where(id: @cart.keys).map do |event|
      { event: event, quantity: @cart[event.id.to_s].to_i }
    end
    @total = @events.sum { |item| item[:event].price * item[:quantity] }
  end

  def add_item
    event = Event.find(params[:event_id])
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1

    session[:cart] ||= {}
    key = event.id.to_s
    current_qty = session[:cart][key].to_i
    new_qty = [current_qty + quantity, event.tickets_available].min
    session[:cart][key] = new_qty
    redirect_to cart_path, notice: "Item added to cart"
  end

  def remove_item
    event_id = params[:event_id].to_s
    if session[:cart] && session[:cart][event_id]
      current_qty = session[:cart][event_id].to_i
      if current_qty > 1
        session[:cart][event_id] = current_qty - 1
        redirect_to cart_path, notice: "Item quantity decreased"
      else
        session[:cart].delete(event_id)
        redirect_to cart_path, notice: "Item removed from cart"
      end
    else
      redirect_to cart_path, alert: "Item not found in cart"
    end
  end

  def set_type
    event_id = params[:event_id].to_s
    ticket_type = params[:ticket_type].to_s
    allowed = %w[Adult Child]
    unless allowed.include?(ticket_type)
      redirect_to cart_path, alert: "Invalid ticket type." and return
    end

    if session[:cart] && session[:cart].key?(event_id)
      session[:ticket_types] ||= {}
      session[:ticket_types][event_id] = ticket_type
      redirect_to cart_path, notice: "Ticket type updated."
    else
      redirect_to cart_path, alert: "Item not found in cart"
    end
  end

  def clear
    session[:cart] = {}
    redirect_to cart_path, notice: "Cart cleared"
  end

  def purchase
    @cart = session[:cart] || {}
    @events = Event.where(id: @cart.keys).map do |event|
      { event: event, quantity: @cart[event.id.to_s].to_i }
    end
    @total = @events.sum { |item| item[:event].price * item[:quantity] }

    if @cart.any?
      purchased_items = []
      total_paid = 0

      ActiveRecord::Base.transaction do
        @events.each do |item|
          event = Event.lock("FOR UPDATE").find(item[:event].id)
          quantity = item[:quantity].to_i
          next if quantity <= 0

          if event.tickets_available >= quantity
            event.update!(tickets_available: event.tickets_available - quantity)

            current_user.purchases.create!(
              event: event,
              quantity: quantity,
              total_price: event.price * quantity,
              ticket_type: (session[:ticket_types] || {})[event.id.to_s].presence || 'Adult',
              purchased_at: Time.current
            )

            purchased_items << {
              id: event.id,
              name: event.name,
              quantity: quantity,
              price: event.price,
              subtotal: event.price * quantity
            }
            total_paid += event.price * quantity
          else
            raise ActiveRecord::Rollback, "Not enough tickets available for #{event.name}"
          end
        end
      end

      if purchased_items.any?
        session[:last_purchase_items] = purchased_items.sum { |i| i[:quantity] }
        session[:last_purchase_total] = total_paid
        # Clean up cart and corresponding ticket types
        purchased_ids = @events.map { |i| i[:event].id.to_s }
        session[:cart] = {}
        (session[:ticket_types] || {}).slice!(*purchased_ids)
        redirect_to confirmation_path, notice: "Purchase completed successfully!"
      else
        redirect_to cart_path, alert: "Cart has invalid quantities."
      end
    else
      flash[:alert] = "Cart is empty"
      redirect_to cart_path
    end
  end
end