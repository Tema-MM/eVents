class TicketsController < ApplicationController
  before_action :authenticate_user!

  def index
    @purchases = current_user.purchases.includes(:event).order(purchased_at: :desc)
  end

  def download
    explicit_ids = Array(params[:purchase_ids]).map(&:to_i).reject(&:zero?)
    recent_ids = Array(session[:recent_purchase_ids]).map(&:to_i).reject(&:zero?)
    target_ids = if explicit_ids.present?
                   explicit_ids
                 elsif recent_ids.present?
                   recent_ids
                 else
                   []
                 end

    @purchases = if target_ids.present?
                   current_user.purchases.includes(:event).where(id: target_ids)
                 else
                   current_user.purchases.includes(:event).order(purchased_at: :desc).limit(5)
                 end
    if @purchases.blank?
      redirect_to confirmation_path, alert: "No purchases available to download." and return
    end
    respond_to do |format|
      format.pdf do
        render pdf: "tickets_#{Time.current.to_i}", template: "tickets/download", formats: [:pdf], layout: false
      end
    end
  end

  def send_email
    explicit_ids = Array(params[:purchase_ids]).map(&:to_i).reject(&:zero?)
    recent_ids = Array(session[:recent_purchase_ids]).map(&:to_i).reject(&:zero?)
    target_ids = explicit_ids.presence || recent_ids.presence
    purchases = if target_ids.present?
                  current_user.purchases.where(id: target_ids)
                else
                  current_user.purchases.order(purchased_at: :desc).limit(5)
                end
    if purchases.blank?
      redirect_to confirmation_path, alert: "No purchases available to email." and return
    end

    recipient_email = params[:email].presence || current_user.email
    TicketEmailJob.perform_later(current_user.id, target_ids, recipient_email)
    redirect_to confirmation_path, notice: "We are sending your tickets to #{recipient_email}."
  end
end