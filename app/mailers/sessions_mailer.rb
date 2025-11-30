class SessionsMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @token = token
    @magic_link_url = magic_link_url(token: token.token)

    mail(
      to: user.email,
      subject: "Sign in to Hackatime"
    )
  end
end
