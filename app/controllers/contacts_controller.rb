class ContactsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      ContactMailer.with(contact: @contact).new_contact_email.deliver_later
      flash[:success] = "送信が完了しました"
      redirect_to new_contact_path
    else
      flash.now[:danger] = "お問い合わせの送信に失敗しました。"
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :message)
  end
end
