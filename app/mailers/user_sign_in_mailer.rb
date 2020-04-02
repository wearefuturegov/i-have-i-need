class UserSignInMailer < ApplicationMailer
  default :from => Rails.configuration.councils[ENV['COUNCIL'] || :demo][:default_from_address]

  def send_invite_email(user)
    mail(:to => user.email, :subject => "You've been invited")
  end
end
