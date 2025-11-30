class StaticPagesController < ApplicationController
  def index
    if logged_in?
      @today_duration = current_user.today_duration
      @today_languages = current_user.today_heartbeats.calculate_duration_by(:language).first(5)
      @today_editors = current_user.today_heartbeats.calculate_duration_by(:editor).first(5)
      @today_projects = current_user.today_heartbeats.calculate_duration_by(:project).first(5)
      @streak = current_user.streak_count
      @leaderboard = LeaderboardService.daily_leaderboard
      @currently_hacking = User.joins(:heartbeats)
                               .where("heartbeats.time > ?", 5.minutes.ago.to_i)
                               .distinct
                               .limit(10)
    end
  end

  def about
  end

  def privacy
  end

  def terms
  end
end
