class UserMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'

  def ticket_email
    @user = params[:user]
    @purchases = params[:purchases]
    recipient_email = params[:recipient_email].presence || @user.email

    # Generate PDF attachment from tickets template (HTML rendered, then converted by WickedPDF)
    pdf_html = ApplicationController.render(
      template: 'tickets/download',
      layout: false,
      assigns: { '@purchases' => @purchases }
    )
    pdf_binary = WickedPdf.new.pdf_from_string(pdf_html)
    attachments["tickets_#{Time.current.to_i}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf_binary
    }

    mail(to: recipient_email, subject: 'Your Event Tickets')
  end
end