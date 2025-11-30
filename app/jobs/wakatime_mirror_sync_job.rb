class WakatimeMirrorSyncJob < ApplicationJob
  queue_as :latency_1m

  def perform(mirror_id, heartbeat_id)
    mirror = WakatimeMirror.find(mirror_id)
    heartbeat = Heartbeat.find(heartbeat_id)

    return unless mirror.enabled?
    return if mirror.api_key_ciphertext.blank?

    # Note: In production, you would decrypt the API key here using
    # Rails credentials or attr_encrypted gem. For now, we're using
    # the value directly as a placeholder.
    api_key = mirror.api_key_ciphertext

    uri = URI("#{mirror.endpoint}/api/v1/users/current/heartbeats")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      time: heartbeat.time,
      entity: heartbeat.entity,
      project: heartbeat.project,
      language: heartbeat.language,
      branch: heartbeat.branch,
      is_write: heartbeat.is_write,
      category: heartbeat.category
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess) || response.code == "201"
      Rails.logger.warn "WakaTime mirror sync failed for mirror #{mirror_id}: #{response.code}"
    end
  rescue => e
    Rails.logger.error "WakaTime mirror sync error: #{e.message}"
  end
end
