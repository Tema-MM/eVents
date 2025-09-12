class ConfirmationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @purchases = current_user.purchases.order(purchased_at: :desc).limit(5) # Show last 5 purchases
    @total_purchased = @purchases.sum { |p| p.total_price }
  end
end