module Api
  module V1
    module Integrity
      class AnalyticsController < BaseController
        before_action :require_teacher!

        # Constants for trust score calculations
        FLAG_IMPACT_SCORE = -10  # Base score deduction per confirmed flag
        SESSION_TIMEOUT_SECONDS = 120  # 2 minute timeout between heartbeats

        # GET /api/v1/integrity/analytics/coding-patterns/:user_id
        def coding_patterns
          user = User.find(params[:user_id])

          unless user.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          days = (params[:days] || 30).to_i.clamp(1, 365)
          heartbeats = user.heartbeats.where("time > ?", days.days.ago.to_i)

          render json: {
            user: {
              id: user.id,
              username: user.display_username
            },
            period_days: days,
            patterns: {
              daily_activity: calculate_daily_activity(heartbeats, days),
              hourly_distribution: calculate_hourly_distribution(heartbeats),
              language_usage: heartbeats.group(:language).count.sort_by { |_, v| -v }.first(10).to_h,
              editor_usage: heartbeats.group(:editor).count,
              project_activity: calculate_project_activity(heartbeats),
              session_analysis: analyze_sessions(heartbeats)
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        end

        # GET /api/v1/integrity/analytics/similarity/:submission_id
        def similarity
          submission = Submission.find(params[:submission_id])

          unless submission.assignment.classroom.teacher == @current_user || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          # Get all similarity reports for this submission
          reports = submission.similarity_reports.includes(:compared_submission).order(similarity_score: :desc)

          render json: {
            submission: {
              id: submission.id,
              student: submission.student.display_username,
              project: submission.project_name
            },
            total_comparisons: reports.count,
            high_similarity_count: reports.count { |r| r.similarity_score >= 80 },
            reports: reports.map { |r| similarity_report_response(r) }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Submission not found" }, status: :not_found
        end

        # GET /api/v1/integrity/analytics/trust-trend/:user_id
        def trust_trend
          user = User.find(params[:user_id])

          unless user.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          render json: {
            user: {
              id: user.id,
              username: user.display_username
            },
            current_trust_score: user.trust_score,
            trust_level: user.trust_level,
            trend: calculate_trust_trend(user),
            flag_impact: calculate_flag_impact(user)
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        end

        private

        def calculate_daily_activity(heartbeats, days)
          start_date = days.days.ago.to_date

          (start_date..Date.current).map do |date|
            day_heartbeats = heartbeats.select { |h| Time.at(h.time).to_date == date }
            {
              date: date.to_s,
              heartbeat_count: day_heartbeats.count,
              coding_time: calculate_duration_for_heartbeats(day_heartbeats)
            }
          end
        end

        def calculate_hourly_distribution(heartbeats)
          distribution = Array.new(24, 0)

          heartbeats.each do |h|
            hour = Time.at(h.time).hour
            distribution[hour] += 1
          end

          distribution.each_with_index.map { |count, hour| { hour: hour, count: count } }
        end

        def calculate_project_activity(heartbeats)
          heartbeats.group(:project).count
                   .sort_by { |_, v| -v }
                   .first(10)
                   .map { |project, count| { project: project, heartbeat_count: count } }
        end

        def analyze_sessions(heartbeats)
          return {} if heartbeats.empty?

          sessions = find_sessions(heartbeats)

          return {} if sessions.empty?

          durations = sessions.map { |s| s[:duration] }

          {
            total_sessions: sessions.count,
            average_duration_seconds: (durations.sum / durations.count).round,
            average_duration_formatted: format_duration(durations.sum / durations.count),
            longest_session_seconds: durations.max,
            shortest_session_seconds: durations.min,
            typical_break_duration: calculate_typical_break(sessions)
          }
        end

        def find_sessions(heartbeats)
          sorted = heartbeats.sort_by(&:time)
          sessions = []

          return sessions if sorted.empty?

          current_start = sorted.first.time
          current_end = sorted.first.time

          sorted.each_cons(2) do |prev, curr|
            gap = curr.time - prev.time

            if gap <= SESSION_TIMEOUT_SECONDS
              current_end = curr.time
            else
              duration = current_end - current_start
              sessions << { start: current_start, end: current_end, duration: duration } if duration > 0
              current_start = curr.time
              current_end = curr.time
            end
          end

          duration = current_end - current_start
          sessions << { start: current_start, end: current_end, duration: duration } if duration > 0

          sessions
        end

        def calculate_typical_break(sessions)
          return 0 if sessions.count < 2

          breaks = sessions.each_cons(2).map { |a, b| b[:start] - a[:end] }
          breaks.any? ? (breaks.sum / breaks.count).round : 0
        end

        def calculate_duration_for_heartbeats(heartbeats)
          return 0 if heartbeats.empty?

          sorted = heartbeats.sort_by(&:time)
          total = 0

          sorted.each_cons(2) do |a, b|
            gap = b.time - a.time
            total += [ gap, SESSION_TIMEOUT_SECONDS ].min
          end

          total
        end

        def similarity_report_response(report)
          {
            compared_submission_id: report.compared_submission_id,
            compared_student: report.compared_submission.student.display_username,
            similarity_score: report.similarity_score,
            matched_lines: report.matched_lines,
            report_data: report.report_data,
            created_at: report.created_at.iso8601
          }
        end

        def calculate_trust_trend(user)
          # Get flags from last 90 days grouped by month
          flags = user.flags.where("created_at > ?", 90.days.ago)
                      .group_by { |f| f.created_at.beginning_of_month }

          months = flags.map do |month, month_flags|
            confirmed = month_flags.count { |f| f.status_confirmed? }
            {
              month: month.strftime("%Y-%m"),
              total_flags: month_flags.count,
              confirmed_flags: confirmed,
              score_impact: confirmed * -10 # Rough estimate
            }
          end

          {
            recent_months: months,
            overall_trend: calculate_overall_trend(months)
          }
        end

        def calculate_overall_trend(months)
          return "stable" if months.empty?

          recent_impact = months.last(2).sum { |m| m[:score_impact] }

          if recent_impact < -20
            "declining"
          elsif recent_impact > 0
            "improving"
          else
            "stable"
          end
        end

        def calculate_flag_impact(user)
          flags = user.flags.status_confirmed

          impact_by_type = flags.group(:flag_type).count.transform_values do |count|
            count * FLAG_IMPACT_SCORE
          end

          {
            total_deductions: impact_by_type.values.sum,
            by_type: impact_by_type
          }
        end
      end
    end
  end
end
