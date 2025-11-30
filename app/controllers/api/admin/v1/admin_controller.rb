module Api
  module Admin
    module V1
      class AdminController < ActionController::API
        before_action :authenticate_admin!

        # GET /api/admin/v1/check
        def check
          render json: { admin: true, level: @current_user.admin_level }
        end

        # GET /api/admin/v1/user/info
        def user_info
          user = find_user
          return unless user

          render json: {
            id: user.id,
            username: user.display_username,
            email: user.email,
            trust_level: user.trust_level,
            admin_level: user.admin_level,
            created_at: user.created_at.iso8601,
            heartbeats_count: user.heartbeats.count
          }
        end

        # GET /api/admin/v1/user/stats
        def user_stats
          user = find_user
          return unless user

          days = (params[:days] || 7).to_i.clamp(1, 365)
          heartbeats = user.heartbeats.last_n_days(days, user.timezone || "UTC")

          render json: {
            user_id: user.id,
            total_seconds: heartbeats.calculate_duration,
            heartbeat_count: heartbeats.count,
            languages: heartbeats.calculate_duration_by(:language).first(10).to_h,
            projects: heartbeats.calculate_duration_by(:project).first(10).to_h
          }
        end

        # POST /api/admin/v1/user/convict
        def user_convict
          user = find_user
          return unless user

          old_trust_level = user.trust_level_before_type_cast
          new_trust_level = params[:trust_level]

          unless User.trust_levels.key?(new_trust_level)
            return render json: { error: "Invalid trust level" }, status: :unprocessable_entity
          end

          if user.update(trust_level: new_trust_level)
            TrustLevelAuditLog.create!(
              user: user,
              admin: @current_user,
              old_trust_level: old_trust_level,
              new_trust_level: User.trust_levels[new_trust_level],
              reason: params[:reason]
            )
            render json: { success: true, new_trust_level: user.trust_level }
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/admin/v1/execute
        def execute
          action = params[:action_type]

          case action
          when "rebuild_leaderboards"
            LeaderboardUpdateJob.perform_later(:daily, Date.current)
            LeaderboardUpdateJob.perform_later(:last_7_days, Date.current)
            render json: { success: true, message: "Leaderboards rebuild queued" }
          when "clear_cache"
            Rails.cache.clear
            render json: { success: true, message: "Cache cleared" }
          else
            render json: { error: "Unknown action" }, status: :unprocessable_entity
          end
        end

        private

        def authenticate_admin!
          token = extract_token
          return render_unauthorized if token.blank?

          api_key = ApiKey.authenticate(token)
          return render_unauthorized if api_key.nil?

          @current_user = api_key.user
          return render_forbidden unless @current_user.admin?
        end

        def extract_token
          auth_header = request.headers["Authorization"]
          if auth_header&.start_with?("Bearer ")
            auth_header.sub("Bearer ", "")
          elsif auth_header&.start_with?("Basic ")
            Base64.decode64(auth_header.sub("Basic ", "")).split(":").first
          else
            params[:api_key]
          end
        end

        def find_user
          user = if params[:user_id]
            User.find_by(id: params[:user_id])
          elsif params[:username]
            User.find_by(username: params[:username])
          elsif params[:slack_uid]
            User.find_by(slack_uid: params[:slack_uid])
          end

          unless user
            render json: { error: "User not found" }, status: :not_found
            return nil
          end

          user
        end

        def render_unauthorized
          render json: { error: "Unauthorized" }, status: :unauthorized
        end

        def render_forbidden
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end
    end
  end
end
