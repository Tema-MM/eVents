class TicketsController < ApplicationController
  before_action :authenticate_user!

  def download
    @purchases = current_user.purchases.order(purchased_at: :desc).limit(5)
    respond_to do |format|
      format.pdf do
        render pdf: "tickets_#{Time.current.to_i}", template: "tickets/download.pdf.erb", layout: false
      end
    end
  end

  def send_email
    @purchases = current_user.purchases.order(purchased_at: :desc).limit(5)
    UserMailer.with(user: current_user, purchases: @purchases).ticket_email.deliver_now
    redirect_to confirmation_path, notice: "Tickets sent to your email!"
  end
end