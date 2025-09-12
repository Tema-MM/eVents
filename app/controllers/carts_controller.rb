class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = session[:cart] || {}
    @events = Event.where(id: @cart.keys).map do |event|
      { event: event, quantity: @cart[event.id.to_s] }
    end
    @total = @events.sum { |item| item[:event].price * item[:quantity] }
  end

  def add_item
    event_id = params[:event_id]
    quantity = params[:quantity].to_i
    session[:cart] ||= {}
    session[:cart][event_id] ||= 0
    session[:cart][event_id] += quantity
    redirect_to cart_path, notice: "Item added to cart"
  end

  def remove_item
    event_id = params[:event_id]
    if session[:cart] && session[:cart][event_id]
      session[:cart].delete(event_id)
      redirect_to cart_path, notice: "Item removed from cart"
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
      { event: event, quantity: @cart[event.id.to_s] }
    end
    @total = @events.sum { |item| item[:event].price * item[:quantity] }

    if @cart.any?
      @events.each do |item|
        event = item[:event]
        quantity = item[:quantity]
        if event.tickets_available >= quantity
          event.tickets_available -= quantity
          event.save
          # Create purchase record
          current_user.purchases.create!(
            event: event,
            quantity: quantity,
            total_price: event.price * quantity,
            purchased_at: Time.current
          )
        else
          flash[:alert] = "Not enough tickets available for #{event.name}"
          redirect_to cart_path and return
        end
      end
      session[:cart] = {} # Clear cart after successful purchase
      redirect_to confirmation_path, notice: "Purchase completed successfully!"
    else
      flash[:alert] = "Cart is empty"
      redirect_to cart_path
    end
  end
end