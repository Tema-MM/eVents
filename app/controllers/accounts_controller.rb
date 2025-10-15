class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @recent_purchases = @user.purchases.includes(:event).order(purchased_at: :desc).limit(5)
  end
end
