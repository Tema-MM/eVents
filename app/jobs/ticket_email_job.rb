class TicketEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, purchase_ids = nil, recipient_email = nil)
    user = User.find_by(id: user_id)
    return unless user

    purchases = if purchase_ids.present?
                  user.purchases.where(id: purchase_ids)
                else
                  user.purchases.order(purchased_at: :desc).limit(5)
                end
    UserMailer.with(user: user, purchases: purchases, recipient_email: recipient_email).ticket_email.deliver_now
  end
end
