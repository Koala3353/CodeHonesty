class LeaderboardService
  class << self
    # Get or build the daily leaderboard for a given date
    def daily_leaderboard(date = Date.current)
      leaderboard = Leaderboard.for_date(date, period_type: :daily)

      unless leaderboard.finished?
        LeaderboardUpdateJob.perform_later(:daily, date.to_s)
      end

      leaderboard
    end

    # Get or build the weekly leaderboard for a given date
    def weekly_leaderboard(date = Date.current)
      leaderboard = Leaderboard.for_date(date, period_type: :last_7_days)

      unless leaderboard.finished?
        LeaderboardUpdateJob.perform_later(:last_7_days, date.to_s)
      end

      leaderboard
    end

    # Rebuild a leaderboard with fresh data
    def rebuild_leaderboard(leaderboard)
      LeaderboardBuilder.new(leaderboard).build!
    end
  end
end
