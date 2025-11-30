module Api
  module V1
    module Integrity
      class SubmissionsController < BaseController
        before_action :set_submission

        # GET /api/v1/integrity/submissions/:id
        def show
          render json: { submission: submission_detail_response(@submission) }
        end

        # GET /api/v1/integrity/submissions/:id/heartbeats
        def heartbeats
          heartbeats = @submission.heartbeats.order(:time)

          render json: {
            submission_id: @submission.id,
            project: @submission.project_name,
            heartbeats: heartbeats.map { |h| heartbeat_response(h) }
          }
        end

        # GET /api/v1/integrity/submissions/:id/timeline
        def timeline
          heartbeats = @submission.heartbeats.order(:time)

          # Group heartbeats by hour
          hourly = heartbeats.group_by { |h| Time.at(h.time).beginning_of_hour }

          render json: {
            submission_id: @submission.id,
            timeline: hourly.map do |hour, hbs|
              {
                hour: hour.iso8601,
                heartbeat_count: hbs.count,
                languages: hbs.map(&:language).compact.tally,
                files_touched: hbs.map(&:entity).compact.uniq.count,
                write_count: hbs.count(&:is_write)
              }
            end
          }
        end

        # GET /api/v1/integrity/submissions/:id/analysis
        def analysis
          render json: {
            submission_id: @submission.id,
            trust_score: @submission.trust_score,
            total_coding_time: @submission.total_coding_time,
            total_coding_time_formatted: format_duration(@submission.total_coding_time || 0),
            flags: @submission.flags.map { |f| flag_response(f) },
            similarity_reports: @submission.similarity_reports.map { |s| similarity_response(s) },
            heartbeat_stats: heartbeat_stats(@submission)
          }
        end

        private

        def set_submission
          @submission = Submission.find(params[:id])

          # Check access - must be the student, the teacher, or admin
          teacher = @submission.assignment.classroom.teacher
          unless @submission.student == @current_user || teacher == @current_user || @current_user.admin?
            render json: { error: "Not authorized" }, status: :forbidden
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Submission not found" }, status: :not_found
        end

        def submission_detail_response(submission)
          {
            id: submission.id,
            assignment: {
              id: submission.assignment.id,
              title: submission.assignment.title,
              due_date: submission.assignment.due_date.iso8601,
              expected_hours: submission.assignment.expected_hours
            },
            student: {
              id: submission.student.id,
              username: submission.student.display_username,
              trust_score: submission.student.trust_score
            },
            project_name: submission.project_name,
            submitted_at: submission.submitted_at&.iso8601,
            status: submission.status,
            trust_score: submission.trust_score,
            total_coding_time: submission.total_coding_time,
            total_coding_time_formatted: format_duration(submission.total_coding_time || 0),
            flags: submission.flags.map { |f| flag_response(f) },
            created_at: submission.created_at.iso8601
          }
        end

        def heartbeat_response(heartbeat)
          {
            id: heartbeat.id,
            time: Time.at(heartbeat.time).iso8601,
            entity: heartbeat.entity,
            language: heartbeat.language,
            editor: heartbeat.editor,
            branch: heartbeat.branch,
            is_write: heartbeat.is_write,
            lines: heartbeat.lines
          }
        end

        def flag_response(flag)
          {
            id: flag.id,
            type: flag.flag_type,
            severity: flag.severity,
            description: flag.description,
            status: flag.status,
            evidence: flag.evidence,
            created_at: flag.created_at.iso8601
          }
        end

        def similarity_response(report)
          {
            id: report.id,
            compared_submission_id: report.compared_submission_id,
            compared_student: report.compared_submission.student.display_username,
            similarity_score: report.similarity_score,
            matched_lines: report.matched_lines,
            created_at: report.created_at.iso8601
          }
        end

        def heartbeat_stats(submission)
          heartbeats = submission.heartbeats

          return {} if heartbeats.empty?

          {
            total_heartbeats: heartbeats.count,
            write_heartbeats: heartbeats.where(is_write: true).count,
            unique_files: heartbeats.distinct.count(:entity),
            languages: heartbeats.group(:language).count,
            editors: heartbeats.group(:editor).count,
            first_activity: Time.at(heartbeats.minimum(:time)).iso8601,
            last_activity: Time.at(heartbeats.maximum(:time)).iso8601
          }
        end
      end
    end
  end
end
