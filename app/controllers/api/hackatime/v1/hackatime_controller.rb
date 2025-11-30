module Api
  module Hackatime
    module V1
      class HackatimeController < ActionController::API
        before_action :authenticate_api_key!

        # POST /api/hackatime/v1/users/:id/heartbeats
        def create_heartbeat
          heartbeat = @current_user.heartbeats.new(heartbeat_params)

          if heartbeat.save
            queue_side_effects(heartbeat)
            render json: { data: heartbeat_response(heartbeat) }, status: :created
          else
            render json: { errors: heartbeat.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/hackatime/v1/users/:id/heartbeats.bulk
        def create_heartbeats_bulk
          heartbeats_data = params[:heartbeats] || []
          results = []
          created_count = 0
          duplicate_count = 0

          heartbeats_data.each do |hb_params|
            heartbeat = @current_user.heartbeats.new(
              time: hb_params[:time],
              entity: hb_params[:entity],
              project: hb_params[:project],
              language: hb_params[:language],
              editor: extract_editor,
              operating_system: extract_os,
              branch: hb_params[:branch],
              machine: hb_params[:machine],
              category: hb_params[:category] || "coding",
              is_write: hb_params[:is_write] || false,
              lines: hb_params[:lines],
              lineno: hb_params[:lineno],
              cursorpos: hb_params[:cursorpos]
            )

            if heartbeat.save
              queue_side_effects(heartbeat)
              results << { status: 201 }
              created_count += 1
            elsif heartbeat.errors[:fields_hash].any?
              results << { status: 201 } # Duplicate - treat as success
              duplicate_count += 1
            else
              results << { status: 400, error: heartbeat.errors.full_messages.first }
            end
          end

          render json: {
            responses: results,
            created: created_count,
            duplicates: duplicate_count
          }, status: :created
        end

        # GET /api/hackatime/v1/users/:id/statusbar/today
        def statusbar_today
          today_duration = @current_user.today_duration
          today_heartbeats = @current_user.today_heartbeats

          render json: {
            data: {
              grand_total: {
                decimal: format("%.2f", today_duration / 3600.0),
                digital: format_digital(today_duration),
                hours: today_duration / 3600,
                minutes: (today_duration % 3600) / 60,
                text: format_text(today_duration),
                total_seconds: today_duration
              },
              categories: [],
              editors: today_heartbeats.calculate_duration_by(:editor).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, today_duration) }
              },
              languages: today_heartbeats.calculate_duration_by(:language).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, today_duration) }
              },
              projects: today_heartbeats.calculate_duration_by(:project).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, today_duration) }
              }
            }
          }
        end

        # GET /api/hackatime/v1/users/current/stats/last_7_days
        def stats_last_7_days
          heartbeats = @current_user.heartbeats.last_n_days(7, @current_user.timezone || "UTC")
          total_duration = heartbeats.calculate_duration

          render json: {
            data: {
              best_day: nil, # TODO: Calculate best day
              created_at: Time.current.iso8601,
              daily_average: total_duration / 7,
              days_including_holidays: 7,
              days_minus_holidays: 7,
              editors: heartbeats.calculate_duration_by(:editor).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, total_duration) }
              },
              human_readable_daily_average: format_text(total_duration / 7),
              human_readable_total: format_text(total_duration),
              is_already_updating: false,
              is_stuck: false,
              is_up_to_date: true,
              languages: heartbeats.calculate_duration_by(:language).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, total_duration) }
              },
              projects: heartbeats.calculate_duration_by(:project).map { |name, secs|
                { name: name, total_seconds: secs, percent: safe_percent(secs, total_duration) }
              },
              range: {
                end: Date.current.to_s,
                start: 6.days.ago.to_date.to_s,
                text: "Last 7 Days"
              },
              total_seconds: total_duration,
              total_seconds_including_other_language: total_duration,
              username: @current_user.display_username
            }
          }
        end

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

        def extract_token
          # Check Authorization header
          auth_header = request.headers["Authorization"]
          if auth_header.present?
            if auth_header.start_with?("Bearer ")
              return auth_header.sub("Bearer ", "")
            elsif auth_header.start_with?("Basic ")
              decoded = Base64.decode64(auth_header.sub("Basic ", ""))
              # WakaTime sends api_key as username with empty password
              return decoded.split(":").first
            end
          end

          # Check query param
          params[:api_key]
        end

        def heartbeat_params
          {
            time: params[:time],
            entity: params[:entity],
            project: params[:project],
            language: params[:language],
            editor: extract_editor,
            operating_system: extract_os,
            branch: params[:branch],
            machine: params[:machine],
            category: params[:category] || "coding",
            is_write: params[:is_write] || false,
            lines: params[:lines],
            lineno: params[:lineno],
            cursorpos: params[:cursorpos]
          }
        end

        def extract_editor
          user_agent = request.headers["User-Agent"] || ""
          # Parse WakaTime user agent format: "wakatime/x.x.x (os-version) editor/version editor-wakatime/version"
          if user_agent.match?(/vscode|code/i)
            "VS Code"
          elsif user_agent.match?(/vim|neovim|nvim/i)
            "Vim"
          elsif user_agent.match?(/intellij|idea|webstorm|pycharm|goland|rubymine/i)
            "JetBrains"
          elsif user_agent.match?(/sublime/i)
            "Sublime Text"
          elsif user_agent.match?(/atom/i)
            "Atom"
          elsif user_agent.match?(/emacs/i)
            "Emacs"
          else
            user_agent.split("/").first || "Unknown"
          end
        end

        def extract_os
          user_agent = request.headers["User-Agent"] || ""
          if user_agent.match?(/mac|darwin/i)
            "macOS"
          elsif user_agent.match?(/windows|win32|win64/i)
            "Windows"
          elsif user_agent.match?(/linux/i)
            "Linux"
          else
            "Unknown"
          end
        end

        def queue_side_effects(heartbeat)
          # Queue job to attempt project-repo mapping
          AttemptProjectRepoMappingJob.perform_later(heartbeat.id)

          # Sync to WakaTime mirrors if configured
          @current_user.wakatime_mirrors.enabled.each do |mirror|
            mirror.sync_heartbeat(heartbeat)
          end
        end

        def heartbeat_response(heartbeat)
          {
            id: heartbeat.id,
            time: heartbeat.time,
            entity: heartbeat.entity,
            project: heartbeat.project,
            language: heartbeat.language,
            branch: heartbeat.branch
          }
        end

        def format_digital(seconds)
          hours = seconds / 3600
          minutes = (seconds % 3600) / 60
          format("%d:%02d", hours, minutes)
        end

        def format_text(seconds)
          hours = seconds / 3600
          minutes = (seconds % 3600) / 60

          if hours > 0
            "#{hours} hr#{'s' if hours != 1} #{minutes} min#{'s' if minutes != 1}"
          else
            "#{minutes} min#{'s' if minutes != 1}"
          end
        end

        def safe_percent(part, total)
          return 0 if total == 0
          ((part.to_f / total) * 100).round(2)
        end
      end
    end
  end
end
