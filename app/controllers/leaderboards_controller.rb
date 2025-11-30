class LeaderboardsController < ApplicationController
  def index
    @period = params[:period] || "daily"
    @date = Date.parse(params[:date]) rescue Date.current

    @leaderboard = case @period
    when "daily"
      LeaderboardService.daily_leaderboard(@date)
    when "last_7_days"
      LeaderboardService.weekly_leaderboard(@date)
    else
      LeaderboardService.daily_leaderboard(@date)
    end

    @entries = @leaderboard&.ranked_entries || []
  end

  def show
    @leaderboard = Leaderboard.find(params[:id])
    @entries = @leaderboard.ranked_entries
  end
end
