# Create app/controllers/purchases_controller.rb
class PurchasesController < ApplicationController
  before_action :authenticate_user!

  def create
    event = Event.find(params[:event_id])
    quantity = params[:quantity].to_i
    if event.tickets_available >= quantity
      event.tickets_available -= quantity
      event.save
      redirect_to root_path, notice: "Purchase successful! You bought #{quantity} tickets for #{event.name}."
    else
      redirect_to event_path(event), alert: "Not enough tickets available."
    end
  end
end