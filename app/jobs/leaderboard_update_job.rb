class LeaderboardUpdateJob < ApplicationJob
  queue_as :latency_5m

  # Ensure only one job runs per period/date combination
  good_job_control_concurrency_with(
    key: -> { "leaderboard_#{arguments[0]}_#{arguments[1]}" },
    total: 1,
    drop: true
  )

  def perform(period_type, date_string = nil)
    date = date_string ? Date.parse(date_string) : Date.current
    period_type = period_type.to_sym

    leaderboard = Leaderboard.for_date(date, period_type: period_type)

    # Skip if already finished and less than 1 hour old
    if leaderboard.finished? && leaderboard.finished_generating_at > 1.hour.ago
      Rails.logger.info "Leaderboard #{period_type} for #{date} already up to date"
      return
    end

    LeaderboardBuilder.new(leaderboard).build!

    # Invalidate cache
    LeaderboardCache.invalidate(period_type, date)

    Rails.logger.info "Leaderboard #{period_type} for #{date} updated successfully"
  end
end
