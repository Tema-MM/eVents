class UserMailerPreview < ActionMailer::Preview
  # Preview at: /rails/mailers/user_mailer/ticket_email
  def ticket_email
    user = User.first || User.new(email: "preview@example.com")
    purchases = if user.respond_to?(:purchases)
                  user.purchases.order(purchased_at: :desc).limit(5)
                else
                  []
                end
    UserMailer.with(user: user, purchases: purchases).ticket_email
  end
end
