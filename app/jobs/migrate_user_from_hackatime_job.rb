class MigrateUserFromHackatimeJob < ApplicationJob
  queue_as :latency_5m

  def perform(user_id, source_url, api_key)
    user = User.find(user_id)

    # Fetch heartbeats from external Hackatime/WakaTime instance
    uri = URI("#{source_url}/api/v1/users/current/heartbeats")
    uri.query = URI.encode_www_form({
      start: 30.days.ago.to_date.to_s,
      end: Date.current.to_s
    })

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{api_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Failed to fetch heartbeats from #{source_url}: #{response.code}"
      return
    end

    data = JSON.parse(response.body)
    heartbeats = data["data"] || data["heartbeats"] || []

    # Import heartbeats
    importer = HeartbeatImportService.new(user, source: :wakapi_import)
    result = importer.import(heartbeats)

    Rails.logger.info "Migration for user #{user.id}: imported=#{result[:imported]}, duplicates=#{result[:duplicates]}, errors=#{result[:errors].size}"
  rescue => e
    Rails.logger.error "Migration failed for user #{user_id}: #{e.message}"
    raise
  end
end
