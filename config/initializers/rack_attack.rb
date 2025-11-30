class Rack::Attack
  # Throttle API requests by IP
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # Throttle heartbeat submissions by API key
  throttle("heartbeats/api_key", limit: 1000, period: 1.hour) do |req|
    if req.path.include?("/heartbeats")
      # Extract API key from various sources
      if req.get_header("HTTP_AUTHORIZATION")&.start_with?("Bearer ")
        req.get_header("HTTP_AUTHORIZATION").sub("Bearer ", "")
      elsif req.get_header("HTTP_AUTHORIZATION")&.start_with?("Basic ")
        Base64.decode64(req.get_header("HTTP_AUTHORIZATION").sub("Basic ", "")).split(":").first rescue nil
      else
        req.params["api_key"]
      end
    end
  end

  # Throttle login attempts by email
  throttle("logins/email", limit: 5, period: 20.minutes) do |req|
    if req.path == "/auth/magic_link" && req.post?
      req.params["email"]&.downcase&.strip
    end
  end

  # Throttle admin API
  throttle("admin/ip", limit: 100, period: 5.minutes) do |req|
    if req.path.start_with?("/api/admin/")
      req.ip
    end
  end

  # Block suspicious requests
  blocklist("block/bad_user_agents") do |req|
    # Block requests with no user agent (except for health checks)
    !req.path.start_with?("/up") && req.user_agent.blank?
  end

  # Safe list for localhost in development
  safelist("allow/localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Customize throttled response
  self.throttled_responder = lambda do |request|
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => "60" },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack
