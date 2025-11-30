class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:failure]

  def new
  end

  def create_from_slack
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_slack(auth)
    session[:user_id] = user.id
    flash[:notice] = "Successfully signed in with Slack!"
    redirect_to root_path
  rescue => e
    Rails.logger.error "Slack OAuth error: #{e.message}"
    flash[:alert] = "Failed to sign in with Slack. Please try again."
    redirect_to root_path
  end

  def create_from_github
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_github(auth, current_user)
    session[:user_id] = user.id
    flash[:notice] = "Successfully linked GitHub account!"
    redirect_to root_path
  rescue => e
    Rails.logger.error "GitHub OAuth error: #{e.message}"
    flash[:alert] = e.message
    redirect_to root_path
  end

  def create_from_email
    token = SignInToken.valid.find_by(token: params[:token])

    if token
      user = token.use!
      session[:user_id] = user.id
      flash[:notice] = "Successfully signed in!"
      redirect_to root_path
    else
      flash[:alert] = "Invalid or expired sign-in link."
      redirect_to new_session_path
    end
  end

  def send_magic_link
    email = params[:email]&.downcase&.strip

    if email.blank?
      flash[:alert] = "Please enter your email address."
      return redirect_to new_session_path
    end

    user = User.find_by(email: email)
    email_address = EmailAddress.find_by(email: email)
    user ||= email_address&.user

    if user
      token = user.sign_in_tokens.create!
      SessionsMailer.magic_link(user, token).deliver_later
    end

    # Always show success to prevent email enumeration
    flash[:notice] = "If an account exists with that email, you'll receive a sign-in link shortly."
    redirect_to new_session_path
  end

  def destroy
    session.delete(:user_id)
    @current_user = nil
    flash[:notice] = "You have been signed out."
    redirect_to root_path
  end

  def failure
    flash[:alert] = "Authentication failed. Please try again."
    redirect_to root_path
  end
end
