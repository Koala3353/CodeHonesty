module Api
  module V1
    module Integrity
      class ClassroomsController < BaseController
        before_action :require_teacher!, except: [ :join, :my_classrooms ]
        before_action :set_classroom, only: [ :show, :update, :destroy, :students, :add_student ]

        # GET /api/v1/integrity/classrooms
        def index
          classrooms = @current_user.taught_classrooms.order(created_at: :desc)

          render json: {
            classrooms: classrooms.map { |c| classroom_response(c) }
          }
        end

        # POST /api/v1/integrity/classrooms
        def create
          classroom = @current_user.taught_classrooms.build(classroom_params)

          if classroom.save
            render json: { classroom: classroom_response(classroom) }, status: :created
          else
            render json: { errors: classroom.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/integrity/classrooms/:id
        def show
          render json: { classroom: classroom_response(@classroom, include_students: true) }
        end

        # PUT /api/v1/integrity/classrooms/:id
        def update
          if @classroom.update(classroom_params)
            render json: { classroom: classroom_response(@classroom) }
          else
            render json: { errors: @classroom.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/integrity/classrooms/:id
        def destroy
          @classroom.destroy
          render json: { message: "Classroom deleted successfully" }
        end

        # GET /api/v1/integrity/classrooms/:id/students
        def students
          students = @classroom.students.order(:username)

          render json: {
            students: students.map { |s| student_response(s) }
          }
        end

        # POST /api/v1/integrity/classrooms/:id/students
        def add_student
          student = User.find_by(username: params[:username]) ||
                   User.find_by(email: params[:email])

          unless student
            return render json: { error: "Student not found" }, status: :not_found
          end

          enrollment = @classroom.enrollments.build(student: student)

          if enrollment.save
            render json: { message: "Student added successfully", student: student_response(student) }, status: :created
          else
            render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/integrity/classrooms/join
        def join
          classroom = Classroom.find_by(code: params[:code]&.upcase)

          unless classroom
            return render json: { error: "Invalid classroom code" }, status: :not_found
          end

          enrollment = classroom.enrollments.build(student: @current_user)

          if enrollment.save
            render json: {
              message: "Successfully joined classroom",
              classroom: classroom_response(classroom)
            }, status: :created
          else
            render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/integrity/my/classrooms
        def my_classrooms
          classrooms = @current_user.enrolled_classrooms.order(created_at: :desc)

          render json: {
            classrooms: classrooms.map { |c| classroom_response(c) }
          }
        end

        private

        def set_classroom
          @classroom = @current_user.taught_classrooms.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Classroom not found" }, status: :not_found
        end

        def classroom_params
          params.permit(:name, :description)
        end

        def classroom_response(classroom, include_students: false)
          response = {
            id: classroom.id,
            name: classroom.name,
            code: classroom.code,
            description: classroom.description,
            teacher: classroom.teacher.display_username,
            student_count: classroom.students.count,
            assignment_count: classroom.assignments.count,
            created_at: classroom.created_at.iso8601
          }

          if include_students
            response[:students] = classroom.students.map { |s| student_response(s) }
          end

          response
        end

        def student_response(student)
          {
            id: student.id,
            username: student.display_username,
            email: student.email,
            trust_score: student.trust_score,
            trust_level: student.trust_level
          }
        end
      end
    end
  end
end
