module Api
  module V1
    class UsersController < ActionController::API
      before_action :set_user, except: [:current]

      # GET /api/v1/users/:username/stats
      def stats
        days = (params[:days] || 7).to_i.clamp(1, 365)
        heartbeats = @user.heartbeats.last_n_days(days, @user.timezone || "UTC")
        total_duration = heartbeats.calculate_duration

        render json: {
          username: @user.display_username,
          total_seconds: total_duration,
          human_readable: format_duration(total_duration),
          languages: heartbeats.calculate_duration_by(:language).first(10).to_h,
          editors: heartbeats.calculate_duration_by(:editor).first(5).to_h,
          projects: heartbeats.calculate_duration_by(:project).first(10).to_h
        }
      end

      # GET /api/v1/users/:username/heartbeats/spans
      def spans
        start_date = Date.parse(params[:start]) rescue 7.days.ago.to_date
        end_date = Date.parse(params[:end]) rescue Date.current

        heartbeats = @user.heartbeats.where(
          time: start_date.beginning_of_day.to_i..end_date.end_of_day.to_i
        )

        spans = heartbeats.to_spans

        render json: {
          username: @user.display_username,
          spans: spans.map { |span|
            {
              start: Time.at(span["start_time"]).iso8601,
              end: Time.at(span["end_time"]).iso8601,
              duration: span["duration"],
              project: span["project"],
              language: span["language"]
            }
          }
        }
      end

      # GET /api/v1/users/:username/projects
      def projects
        projects = @user.heartbeats.select(:project).distinct.pluck(:project).compact

        render json: {
          username: @user.display_username,
          projects: projects
        }
      end

      # GET /api/v1/users/:username/trust_factor
      def trust_factor
        render json: {
          username: @user.display_username,
          trust_level: @user.trust_level,
          can_appear_on_leaderboard: @user.can_appear_on_leaderboard?
        }
      end

      private

      def set_user
        @user = User.find_by!(username: params[:username])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def format_duration(seconds)
        hours = seconds / 3600
        minutes = (seconds % 3600) / 60

        if hours > 0
          "#{hours} hr#{'s' if hours != 1} #{minutes} min#{'s' if minutes != 1}"
        else
          "#{minutes} min#{'s' if minutes != 1}"
        end
      end
    end
  end
end
