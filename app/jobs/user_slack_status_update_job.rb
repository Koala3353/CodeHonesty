class UserSlackStatusUpdateJob < ApplicationJob
  queue_as :latency_10s

  def perform(user_id)
    user = User.find(user_id)

    return if user.slack_access_token_ciphertext.blank?

    # Get the user's current project
    recent_heartbeat = user.heartbeats.order(time: :desc).first
    return unless recent_heartbeat

    # Only update if activity is recent (within last 5 minutes)
    return if Time.at(recent_heartbeat.time) < 5.minutes.ago

    # Update Slack status
    uri = URI("https://slack.com/api/users.profile.set")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{user.slack_access_token_ciphertext}"
    request["Content-Type"] = "application/json"
    request.body = {
      profile: {
        status_text: "Coding on #{recent_heartbeat.project || 'a project'}",
        status_emoji: ":technologist:",
        status_expiration: 15.minutes.from_now.to_i
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "Failed to update Slack status for user #{user_id}: #{response.code}"
    end
  rescue => e
    Rails.logger.error "Slack status update error for user #{user_id}: #{e.message}"
  end
end
