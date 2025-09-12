class UserMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'

  def ticket_email
    @user = params[:user]
    @purchases = params[:purchases]
    mail(to: @user.email, subject: 'Your Event Tickets')
  end
end