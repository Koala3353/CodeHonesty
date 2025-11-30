module Api
  module V1
    class StatsController < ActionController::API
      before_action :require_admin!, only: [:index]

      # GET /api/v1/stats (admin only)
      def index
        render json: {
          total_users: User.count,
          total_heartbeats: Heartbeat.count,
          active_users_today: User.joins(:heartbeats).where("heartbeats.time > ?", Date.current.beginning_of_day.to_i).distinct.count,
          heartbeats_today: Heartbeat.where("time > ?", Date.current.beginning_of_day.to_i).count
        }
      end

      private

      def require_admin!
        authenticate!
        unless @current_user&.admin?
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def authenticate!
        token = extract_token
        return render_unauthorized if token.blank?

        api_key = ApiKey.authenticate(token)
        return render_unauthorized if api_key.nil?

        @current_user = api_key.user
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

      def render_unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
