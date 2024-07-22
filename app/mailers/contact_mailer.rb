class ContactMailer < ApplicationMailer
  def new_contact_email
    @contact = params[:contact]
    mail(to: 'daichiiiii317@icloud.com', subject: '新しいお問い合わせ')
  end
end
