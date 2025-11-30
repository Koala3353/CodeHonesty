Rails.application.config.middleware.use OmniAuth::Builder do
  # Slack OAuth
  provider :slack_openid,
           ENV.fetch("SLACK_CLIENT_ID", ""),
           ENV.fetch("SLACK_CLIENT_SECRET", ""),
           scope: "openid,email,profile",
           redirect_uri: ENV.fetch("SLACK_REDIRECT_URI", "http://localhost:3000/auth/slack/callback")

  # GitHub OAuth
  provider :github,
           ENV.fetch("GITHUB_CLIENT_ID", ""),
           ENV.fetch("GITHUB_CLIENT_SECRET", ""),
           scope: "user:email,read:user,repo"
end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle failures gracefully
OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
