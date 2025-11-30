module Api
  module V1
    module Authenticated
      class MeController < BaseController
        # GET /api/v1/authenticated/me
        def show
          render json: {
            id: current_user.id,
            username: current_user.display_username,
            email: current_user.email,
            avatar_url: current_user.avatar_url,
            timezone: current_user.timezone
          }
        end

        # GET /api/v1/authenticated/hours
        def hours
          days = (params[:days] || 7).to_i.clamp(1, 365)
          heartbeats = current_user.heartbeats.last_n_days(days, current_user.timezone || "UTC")
          total_duration = heartbeats.calculate_duration

          render json: {
            total_seconds: total_duration,
            hours: (total_duration / 3600.0).round(2)
          }
        end

        # GET /api/v1/authenticated/streak
        def streak
          render json: {
            streak: current_user.streak_count
          }
        end

        # GET /api/v1/authenticated/projects
        def projects
          projects = current_user.heartbeats
                                 .select(:project)
                                 .distinct
                                 .pluck(:project)
                                 .compact

          render json: {
            projects: projects
          }
        end

        # GET /api/v1/authenticated/heartbeats/latest
        def heartbeats_latest
          heartbeat = current_user.heartbeats.order(time: :desc).first

          if heartbeat
            render json: {
              id: heartbeat.id,
              time: heartbeat.formatted_time,
              entity: heartbeat.entity,
              project: heartbeat.project,
              language: heartbeat.language,
              editor: heartbeat.editor
            }
          else
            render json: { message: "No heartbeats found" }, status: :not_found
          end
        end

        # GET /api/v1/authenticated/api_keys
        def api_keys
          render json: {
            api_keys: current_user.api_keys.map { |key|
              {
                id: key.id,
                name: key.name,
                created_at: key.created_at.iso8601
              }
            }
          }
        end
      end
    end
  end
end
