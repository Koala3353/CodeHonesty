Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (requires ORM extensions installed).
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    User.find_by(id: session[:user_id]) || redirect_to(new_session_path)
  end

  # If you didn't skip applications controller from Doorkeeper routes, you need to set admin_authenticator
  admin_authenticator do
    user = User.find_by(id: session[:user_id])
    head :forbidden unless user&.admin?
  end

  # Authorization Code expiration time (default: 10 minutes).
  authorization_code_expires_in 10.minutes

  # Access token expiration time (default: 2 hours).
  access_token_expires_in 2.hours

  # Refresh token expiration time
  use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  enable_application_owner confirmation: false

  # Define access token scopes for your provider
  default_scopes :read
  optional_scopes :write, :admin

  # Allow authorization to skip grant screen if already authorized
  skip_authorization do |_resource_owner, _client|
    false
  end

  # Grant flows available
  grant_flows %w[authorization_code client_credentials]
end

# Define custom scopes
Doorkeeper.configure do
  enforce_configured_scopes
end
