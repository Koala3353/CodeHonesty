module Cache
  class HeartbeatCountsJob < ApplicationJob
    queue_as :latency_15m

    def perform
      cache_key = "heartbeat_counts"

      counts = {
        total: Heartbeat.count,
        today: Heartbeat.where("time > ?", Date.current.beginning_of_day.to_i).count,
        this_week: Heartbeat.where("time > ?", 7.days.ago.beginning_of_day.to_i).count,
        this_month: Heartbeat.where("time > ?", 30.days.ago.beginning_of_day.to_i).count
      }

      Rails.cache.write(cache_key, counts, expires_in: 15.minutes)
    end
  end
end
