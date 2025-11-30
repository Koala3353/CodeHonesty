module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @total_heartbeats = Heartbeat.count
      @users_today = User.where("created_at > ?", Date.current.beginning_of_day).count
      @heartbeats_today = Heartbeat.where("time > ?", Date.current.beginning_of_day.to_i).count
      @active_users = User.joins(:heartbeats)
                          .where("heartbeats.time > ?", 1.hour.ago.to_i)
                          .distinct
                          .count
    end
  end
end
