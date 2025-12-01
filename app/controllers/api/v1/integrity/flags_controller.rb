module Api
  module V1
    module Integrity
      class FlagsController < BaseController
        before_action :require_teacher!
        before_action :set_flag, only: [ :show, :review ]

        # GET /api/v1/integrity/flags
        def index
          flags = Flag.joins(user: :enrollments)
                     .joins("INNER JOIN classrooms ON enrollments.classroom_id = classrooms.id")
                     .where(classrooms: { teacher_id: @current_user.id })
                     .includes(:user, :submission, :reviewed_by)
                     .order(created_at: :desc)

          # Optional filters
          flags = flags.where(status: params[:status]) if params[:status].present?
          flags = flags.where(severity: params[:severity]) if params[:severity].present?
          flags = flags.where(flag_type: params[:type]) if params[:type].present?

          render json: {
            flags: flags.map { |f| flag_response(f) }
          }
        end

        # GET /api/v1/integrity/flags/:id
        def show
          render json: { flag: flag_detail_response(@flag) }
        end

        # PUT /api/v1/integrity/flags/:id/review
        def review
          status = params[:status]

          unless %w[confirmed dismissed].include?(status)
            return render json: { error: "Invalid status. Must be 'confirmed' or 'dismissed'" }, status: :unprocessable_entity
          end

          if status == "confirmed"
            @flag.confirm!(@current_user, params[:notes])
          else
            @flag.dismiss!(@current_user, params[:notes])
          end

          # Update user trust score after confirming a flag
          @flag.user.calculate_trust_score! if status == "confirmed"

          render json: {
            message: "Flag #{status}",
            flag: flag_response(@flag)
          }
        end

        # GET /api/v1/integrity/students/:id/flags
        def student_flags
          student = User.find(params[:id])

          # Verify the student is in one of the teacher's classrooms
          unless student.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          flags = student.flags.includes(:submission, :reviewed_by).order(created_at: :desc)

          render json: {
            student: {
              id: student.id,
              username: student.display_username,
              trust_score: student.trust_score
            },
            flags: flags.map { |f| flag_response(f) }
          }
        end

        private

        def set_flag
          @flag = Flag.find(params[:id])

          # Verify access through classroom
          student = @flag.user
          unless student.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            render json: { error: "Not authorized" }, status: :forbidden
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Flag not found" }, status: :not_found
        end

        def flag_response(flag)
          {
            id: flag.id,
            type: flag.flag_type,
            severity: flag.severity,
            description: flag.description,
            status: flag.status,
            user: {
              id: flag.user.id,
              username: flag.user.display_username
            },
            submission_id: flag.submission_id,
            reviewed_by: flag.reviewed_by&.display_username,
            reviewed_at: flag.reviewed_at&.iso8601,
            created_at: flag.created_at.iso8601
          }
        end

        def flag_detail_response(flag)
          response = flag_response(flag)
          response[:evidence] = flag.evidence
          response[:submission] = if flag.submission
            {
              id: flag.submission.id,
              assignment: flag.submission.assignment.title,
              project_name: flag.submission.project_name
            }
          end
          response
        end
      end
    end
  end
end
