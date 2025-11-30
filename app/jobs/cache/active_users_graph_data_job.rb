module Cache
  class ActiveUsersGraphDataJob < ApplicationJob
    queue_as :latency_15m

    def perform
      cache_key = "active_users_graph_data"

      # Get active users per hour for the last 24 hours
      data = (0..23).map do |hours_ago|
        start_time = hours_ago.hours.ago.beginning_of_hour
        end_time = start_time.end_of_hour

        count = User.joins(:heartbeats)
                    .where("heartbeats.time BETWEEN ? AND ?", start_time.to_i, end_time.to_i)
                    .distinct
                    .count

        {
          hour: start_time.hour,
          time: start_time.iso8601,
          active_users: count
        }
      end.reverse

      Rails.cache.write(cache_key, data, expires_in: 15.minutes)
    end
  end
end
