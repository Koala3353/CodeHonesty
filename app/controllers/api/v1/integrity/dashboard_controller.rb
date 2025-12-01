module Api
  module V1
    module Integrity
      class DashboardController < BaseController
        before_action :require_teacher!

        # GET /api/v1/integrity/dashboard/overview
        def overview
          classrooms = @current_user.taught_classrooms.includes(:students, :assignments)

          total_students = classrooms.sum { |c| c.students.count }
          total_assignments = classrooms.sum { |c| c.assignments.count }

          # Get pending flags
          pending_flags = Flag.joins(user: :enrollments)
                             .joins("INNER JOIN classrooms ON enrollments.classroom_id = classrooms.id")
                             .where(classrooms: { teacher_id: @current_user.id })
                             .status_pending

          # Calculate average trust score
          student_ids = classrooms.flat_map { |c| c.students.pluck(:id) }.uniq
          avg_trust = User.where(id: student_ids).average(:trust_score)

          render json: {
            stats: {
              active_classrooms: classrooms.count,
              total_students: total_students,
              total_assignments: total_assignments,
              pending_flags: pending_flags.count,
              average_trust_score: avg_trust&.round(2) || 100
            },
            recent_flags: pending_flags.includes(:user, :submission).limit(10).map { |f| flag_summary(f) },
            classrooms: classrooms.map { |c| classroom_summary(c) }
          }
        end

        # GET /api/v1/integrity/dashboard/classroom/:id/stats
        def classroom_stats
          classroom = @current_user.taught_classrooms.find(params[:id])

          students = classroom.students.includes(:flags, :submissions)
          assignments = classroom.assignments.includes(:submissions)

          render json: {
            classroom: {
              id: classroom.id,
              name: classroom.name,
              code: classroom.code
            },
            stats: {
              total_students: students.count,
              total_assignments: assignments.count,
              submissions_count: classroom.submissions.count,
              flagged_submissions: classroom.submissions.where(status: :flagged).count,
              pending_flags: classroom.flags.status_pending.count,
              average_trust_score: students.average(:trust_score)&.round(2) || 100
            },
            student_breakdown: students.map { |s| student_summary(s, classroom) },
            assignment_breakdown: assignments.map { |a| assignment_summary(a) }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Classroom not found" }, status: :not_found
        end

        # GET /api/v1/integrity/dashboard/student/:id/profile
        def student_profile
          student = User.find(params[:id])

          # Verify access
          unless student.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          render json: {
            student: {
              id: student.id,
              username: student.display_username,
              email: student.email,
              trust_score: student.trust_score,
              trust_level: student.trust_level,
              member_since: student.created_at.iso8601
            },
            coding_patterns: calculate_coding_patterns(student),
            flags_summary: flags_summary(student),
            submissions_summary: submissions_summary(student)
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Student not found" }, status: :not_found
        end

        # GET /api/v1/integrity/dashboard/student/:id/history
        def student_history
          student = User.find(params[:id])

          unless student.enrolled_classrooms.where(teacher: @current_user).exists? || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          # Get historical data for past 30 days - batch load all heartbeats at once
          start_date = 30.days.ago.to_date
          timezone = student.timezone || "UTC"

          # Load all heartbeats for the period in a single query
          tz = TZInfo::Timezone.get(timezone)
          period_start = tz.local_to_utc(start_date.to_time).to_i
          period_end = tz.local_to_utc((Date.current + 1).to_time).to_i

          all_heartbeats = student.heartbeats
                                 .where(time: period_start..period_end)
                                 .order(:time)
                                 .to_a

          # Group heartbeats by date
          heartbeats_by_date = all_heartbeats.group_by do |h|
            tz.to_local(Time.at(h.time)).to_date
          end

          daily_activity = (start_date..Date.current).map do |date|
            day_heartbeats = heartbeats_by_date[date] || []
            {
              date: date.to_s,
              coding_time: calculate_duration_from_array(day_heartbeats),
              heartbeat_count: day_heartbeats.count
            }
          end

          render json: {
            student: {
              id: student.id,
              username: student.display_username
            },
            daily_activity: daily_activity,
            trust_score_trend: calculate_trust_trend(student),
            flags_history: student.flags.order(created_at: :desc).limit(20).map { |f| flag_history_item(f) }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Student not found" }, status: :not_found
        end

        # GET /api/v1/integrity/dashboard/assignment/:id/integrity
        def assignment_integrity
          assignment = Assignment.find(params[:id])

          unless assignment.classroom.teacher == @current_user || @current_user.admin?
            return render json: { error: "Not authorized" }, status: :forbidden
          end

          submissions = assignment.submissions.includes(:student, :flags, :similarity_reports)

          render json: {
            assignment: {
              id: assignment.id,
              title: assignment.title,
              due_date: assignment.due_date.iso8601
            },
            stats: {
              total_submissions: submissions.count,
              average_time: submissions.average(:total_coding_time)&.round || 0,
              average_trust_score: submissions.average(:trust_score)&.round(2) || 100,
              flagged_count: submissions.where(status: :flagged).count
            },
            time_distribution: calculate_time_distribution(submissions),
            similarity_matrix: build_similarity_matrix(submissions),
            flagged_submissions: submissions.where(status: :flagged).map { |s| submission_flag_summary(s) }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Assignment not found" }, status: :not_found
        end

        private

        def flag_summary(flag)
          {
            id: flag.id,
            type: flag.flag_type,
            severity: flag.severity,
            student: flag.user.display_username,
            submission_id: flag.submission_id,
            created_at: flag.created_at.iso8601
          }
        end

        def classroom_summary(classroom)
          {
            id: classroom.id,
            name: classroom.name,
            student_count: classroom.students.count,
            pending_flags: classroom.flags.status_pending.count
          }
        end

        def student_summary(student, classroom)
          submissions = student.submissions.joins(:assignment).where(assignments: { classroom_id: classroom.id })

          {
            id: student.id,
            username: student.display_username,
            trust_score: student.trust_score,
            submissions_count: submissions.count,
            flags_count: student.flags.status_pending.count
          }
        end

        def assignment_summary(assignment)
          {
            id: assignment.id,
            title: assignment.title,
            submissions_count: assignment.submissions.count,
            flagged_count: assignment.flagged_count,
            average_trust_score: assignment.average_trust_score&.round(2)
          }
        end

        def calculate_coding_patterns(student)
          heartbeats = student.heartbeats.where("time > ?", 30.days.ago.to_i)

          return {} if heartbeats.empty?

          # Calculate average session length
          sessions = calculate_sessions(heartbeats)
          avg_session = sessions.any? ? sessions.sum { |s| s[:duration] } / sessions.count : 0

          # Find peak hours
          hour_distribution = heartbeats.group_by { |h| Time.at(h.time).hour }.transform_values(&:count)
          peak_hour = hour_distribution.max_by { |_, count| count }&.first

          {
            average_session_hours: (avg_session / 3600.0).round(2),
            peak_hour: peak_hour,
            total_projects: heartbeats.distinct.count(:project),
            primary_languages: heartbeats.group(:language).count.sort_by { |_, v| -v }.first(3).to_h,
            consistency_score: calculate_consistency(heartbeats)
          }
        end

        def calculate_sessions(heartbeats)
          return [] if heartbeats.empty?

          sessions = []
          sorted = heartbeats.order(:time).to_a

          current_start = sorted.first.time
          current_end = sorted.first.time

          sorted.each_cons(2) do |prev, curr|
            gap = curr.time - prev.time

            if gap <= 120 # 2 minute timeout
              current_end = curr.time
            else
              sessions << { start: current_start, end: current_end, duration: current_end - current_start }
              current_start = curr.time
              current_end = curr.time
            end
          end

          sessions << { start: current_start, end: current_end, duration: current_end - current_start }
          sessions
        end

        def calculate_consistency(heartbeats)
          # Calculate how consistent the user's coding patterns are
          daily_counts = heartbeats.group_by { |h| Time.at(h.time).to_date }.transform_values(&:count)

          return 0 if daily_counts.empty?

          mean = daily_counts.values.sum.to_f / daily_counts.count
          variance = daily_counts.values.map { |v| (v - mean)**2 }.sum / daily_counts.count
          std_dev = Math.sqrt(variance)

          # Higher consistency = lower relative standard deviation
          coefficient_of_variation = mean > 0 ? std_dev / mean : 0
          ((1 - [ coefficient_of_variation, 1 ].min) * 100).round(2)
        end

        def flags_summary(student)
          flags = student.flags

          {
            total: flags.count,
            pending: flags.status_pending.count,
            confirmed: flags.status_confirmed.count,
            dismissed: flags.status_dismissed.count,
            by_severity: {
              critical: flags.severity_critical.count,
              high: flags.severity_high.count,
              medium: flags.severity_medium.count,
              low: flags.severity_low.count
            }
          }
        end

        def submissions_summary(student)
          submissions = student.submissions

          {
            total: submissions.count,
            pending: submissions.status_pending.count,
            submitted: submissions.status_submitted.count,
            flagged: submissions.status_flagged.count,
            approved: submissions.status_approved.count,
            average_trust_score: submissions.average(:trust_score)&.round(2)
          }
        end

        def calculate_trust_trend(student)
          # Simplified trend based on recent flags
          recent_flags = student.flags.where("created_at > ?", 30.days.ago).status_confirmed

          {
            current_score: student.trust_score,
            recent_deductions: recent_flags.count,
            trend: recent_flags.count > 3 ? "declining" : "stable"
          }
        end

        def flag_history_item(flag)
          {
            id: flag.id,
            type: flag.flag_type,
            severity: flag.severity,
            status: flag.status,
            created_at: flag.created_at.iso8601
          }
        end

        def calculate_time_distribution(submissions)
          times = submissions.where.not(total_coding_time: nil).pluck(:total_coding_time)

          return {} if times.empty?

          # Create histogram buckets
          max_time = times.max
          bucket_size = [ max_time / 10, 3600 ].max # At least 1 hour buckets

          buckets = {}
          times.each do |time|
            bucket = (time / bucket_size) * bucket_size
            buckets[bucket] ||= 0
            buckets[bucket] += 1
          end

          buckets.transform_keys { |k| "#{(k / 3600.0).round(1)}-#{((k + bucket_size) / 3600.0).round(1)} hrs" }
        end

        def build_similarity_matrix(submissions)
          matrix = []

          submissions.each do |s|
            s.similarity_reports.each do |report|
              next unless report.similarity_score >= 50 # Only show notable similarities

              matrix << {
                student1: s.student.display_username,
                student2: report.compared_submission.student.display_username,
                similarity: report.similarity_score
              }
            end
          end

          matrix.uniq { |m| [ m[:student1], m[:student2] ].sort }
        end

        def submission_flag_summary(submission)
          {
            id: submission.id,
            student: submission.student.display_username,
            trust_score: submission.trust_score,
            total_coding_time: format_duration(submission.total_coding_time || 0),
            flags: submission.flags.map { |f| { type: f.flag_type, severity: f.severity } }
          }
        end

        # Calculate duration from an array of heartbeats (avoids N+1 queries)
        def calculate_duration_from_array(heartbeats)
          return 0 if heartbeats.empty?

          sorted = heartbeats.sort_by(&:time)
          total = 0
          timeout = 120 # 2 minute timeout

          sorted.each_cons(2) do |a, b|
            gap = b.time - a.time
            total += [ gap, timeout ].min
          end

          total
        end
      end
    end
  end
end
