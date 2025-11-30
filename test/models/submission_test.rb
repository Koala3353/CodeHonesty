require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  test "belongs to assignment and student" do
    submission = submissions(:user_submission)
    assert_equal assignments(:homework_one), submission.assignment
    assert_equal users(:regular_user), submission.student
  end

  test "validates unique assignment per student" do
    existing = submissions(:user_submission)
    submission = Submission.new(
      assignment: existing.assignment,
      student: existing.student,
      project_name: "other-project"
    )
    assert_not submission.valid?
    assert submission.errors[:assignment_id].any?
  end

  test "sets default trust score on create" do
    assignment = assignments(:homework_one)
    student = users(:another_user)
    submission = Submission.create!(
      assignment: assignment,
      student: student,
      project_name: "new-project"
    )
    assert_equal 100.0, submission.trust_score
  end

  test "status enum works" do
    submission = submissions(:user_submission)
    assert submission.status_submitted?
    assert_not submission.status_pending?
    assert_not submission.status_flagged?
  end
end
