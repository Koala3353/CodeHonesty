module Api
  module V1
    module Integrity
      class AssignmentsController < BaseController
        before_action :require_teacher!, except: [ :show, :my_assignments, :submit ]
        before_action :set_classroom, only: [ :index, :create ]
        before_action :set_assignment, only: [ :show, :update, :destroy, :submissions ]

        # GET /api/v1/integrity/classrooms/:classroom_id/assignments
        def index
          assignments = @classroom.assignments.order(due_date: :asc)

          render json: {
            assignments: assignments.map { |a| assignment_response(a) }
          }
        end

        # POST /api/v1/integrity/classrooms/:classroom_id/assignments
        def create
          assignment = @classroom.assignments.build(assignment_params)

          if assignment.save
            render json: { assignment: assignment_response(assignment) }, status: :created
          else
            render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/integrity/assignments/:id
        def show
          render json: { assignment: assignment_response(@assignment, include_submissions: teacher?) }
        end

        # PUT /api/v1/integrity/assignments/:id
        def update
          if @assignment.update(assignment_params)
            render json: { assignment: assignment_response(@assignment) }
          else
            render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/integrity/assignments/:id
        def destroy
          @assignment.destroy
          render json: { message: "Assignment deleted successfully" }
        end

        # GET /api/v1/integrity/assignments/:id/submissions
        def submissions
          unless teacher?
            return render json: { error: "Teachers only" }, status: :forbidden
          end

          submissions = @assignment.submissions.includes(:student, :flags).order(submitted_at: :desc)

          render json: {
            submissions: submissions.map { |s| submission_response(s) }
          }
        end

        # GET /api/v1/integrity/my/assignments
        def my_assignments
          classroom_ids = @current_user.enrolled_classrooms.pluck(:id)
          assignments = Assignment.where(classroom_id: classroom_ids).order(due_date: :asc)

          render json: {
            assignments: assignments.map { |a| assignment_with_submission_response(a) }
          }
        end

        # POST /api/v1/integrity/assignments/:id/submit
        def submit
          @assignment = Assignment.find(params[:id])

          unless @current_user.enrolled_classrooms.include?(@assignment.classroom)
            return render json: { error: "Not enrolled in this classroom" }, status: :forbidden
          end

          submission = @assignment.submissions.find_or_initialize_by(student: @current_user)
          submission.assign_attributes(submit_params)
          submission.submitted_at = Time.current
          submission.status = :submitted

          if submission.save
            # Update coding time
            submission.update_coding_time!

            # Run integrity analysis in background
            AnalyzeSubmissionJob.perform_later(submission.id) if defined?(AnalyzeSubmissionJob)

            render json: { submission: submission_response(submission) }, status: :created
          else
            render json: { errors: submission.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def set_classroom
          @classroom = @current_user.taught_classrooms.find(params[:classroom_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Classroom not found" }, status: :not_found
        end

        def set_assignment
          @assignment = Assignment.find(params[:id])

          # Check access
          unless teacher? || @current_user.enrolled_classrooms.include?(@assignment.classroom)
            render json: { error: "Not authorized" }, status: :forbidden
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Assignment not found" }, status: :not_found
        end

        def teacher?
          @current_user.taught_classrooms.exists?(@assignment.classroom_id) || @current_user.admin?
        end

        def assignment_params
          params.permit(:title, :description, :due_date, :expected_hours)
        end

        def submit_params
          params.permit(:project_name)
        end

        def assignment_response(assignment, include_submissions: false)
          response = {
            id: assignment.id,
            title: assignment.title,
            description: assignment.description,
            due_date: assignment.due_date.iso8601,
            expected_hours: assignment.expected_hours,
            past_due: assignment.past_due?,
            classroom: {
              id: assignment.classroom.id,
              name: assignment.classroom.name
            },
            submission_count: assignment.submissions.count,
            flagged_count: assignment.flagged_count,
            average_trust_score: assignment.average_trust_score&.round(2),
            created_at: assignment.created_at.iso8601
          }

          if include_submissions
            response[:submissions] = assignment.submissions.map { |s| submission_response(s) }
          end

          response
        end

        def assignment_with_submission_response(assignment)
          response = assignment_response(assignment)
          submission = assignment.submissions.find_by(student: @current_user)

          response[:my_submission] = submission ? submission_response(submission) : nil
          response
        end

        def submission_response(submission)
          {
            id: submission.id,
            student: submission.student.display_username,
            project_name: submission.project_name,
            submitted_at: submission.submitted_at&.iso8601,
            status: submission.status,
            trust_score: submission.trust_score,
            total_coding_time: submission.total_coding_time,
            total_coding_time_formatted: format_duration(submission.total_coding_time || 0),
            flag_count: submission.flags.pending.count,
            created_at: submission.created_at.iso8601
          }
        end
      end
    end
  end
end
