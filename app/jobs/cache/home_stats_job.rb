module Cache
  class HomeStatsJob < ApplicationJob
    queue_as :latency_15m

    def perform
      cache_key = "home_stats"

      stats = {
        total_users: User.count,
        total_heartbeats: Heartbeat.count,
        total_coding_hours: calculate_total_hours,
        active_today: active_users_today,
        top_languages: top_languages,
        updated_at: Time.current.iso8601
      }

      Rails.cache.write(cache_key, stats, expires_in: 15.minutes)
    end

    private

    def calculate_total_hours
      # Estimate total hours based on heartbeat count and average duration
      # This is an approximation for the homepage
      heartbeat_count = Heartbeat.count
      estimated_seconds = heartbeat_count * 30 # Assume 30 seconds average per heartbeat
      (estimated_seconds / 3600.0).round
    end

    def active_users_today
      User.joins(:heartbeats)
          .where("heartbeats.time > ?", Date.current.beginning_of_day.to_i)
          .distinct
          .count
    end

    def top_languages
      Heartbeat.where("time > ?", 7.days.ago.to_i)
               .group(:language)
               .count
               .sort_by { |_, count| -count }
               .first(10)
               .to_h
    end
  end
end
