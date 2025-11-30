module Api
  module V1
    module Integrity
      class BaseController < ActionController::API
        before_action :authenticate_api_key!

        private

        def authenticate_api_key!
          token = extract_token

          if token.blank?
            return render json: { error: "Unauthorized" }, status: :unauthorized
          end

          api_key = ApiKey.authenticate(token)

          if api_key.nil?
            return render json: { error: "Invalid API key" }, status: :unauthorized
          end

          @current_user = api_key.user
        end

        def require_teacher!
          unless @current_user.teacher? || @current_user.admin?
            render json: { error: "Must be a teacher to access this resource" }, status: :forbidden
          end
        end

        def require_admin!
          unless @current_user.admin?
            render json: { error: "Admin access required" }, status: :forbidden
          end
        end

        def extract_token
          auth_header = request.headers["Authorization"]
          if auth_header.present?
            if auth_header.start_with?("Bearer ")
              return auth_header.sub("Bearer ", "")
            elsif auth_header.start_with?("Basic ")
              decoded = Base64.decode64(auth_header.sub("Basic ", ""))
              return decoded.split(":").first
            end
          end

          params[:api_key]
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
end
