class LeaderboardCache
  CACHE_KEY_PREFIX = "leaderboard"
  CACHE_EXPIRY = 1.hour

  class << self
    def cache_key(period_type, date)
      "#{CACHE_KEY_PREFIX}_#{period_type}_#{date}"
    end

    def cached_leaderboard(period_type, date)
      Rails.cache.fetch(cache_key(period_type, date), expires_in: CACHE_EXPIRY) do
        leaderboard = Leaderboard.find_by(period_type: period_type, start_date: date)
        return nil unless leaderboard&.finished?

        {
          id: leaderboard.id,
          period_type: leaderboard.period_type,
          start_date: leaderboard.start_date,
          entries: leaderboard.ranked_entries.includes(:user).map do |entry|
            {
              rank: entry.rank,
              username: entry.user.display_username,
              avatar_url: entry.user.avatar_url,
              total_seconds: entry.total_seconds,
              streak_count: entry.streak_count
            }
          end
        }
      end
    end

    def invalidate(period_type, date)
      Rails.cache.delete(cache_key(period_type, date))
    end

    def invalidate_all
      # This would require Redis KEYS command or pattern deletion
      # For SolidCache, we can clear all cache or track keys
      Rails.cache.clear
    end
  end
end
