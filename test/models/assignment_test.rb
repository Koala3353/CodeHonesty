require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  test "belongs to classroom" do
    assignment = assignments(:homework_one)
    assert_equal classrooms(:teacher_class), assignment.classroom
  end

  test "validates title presence" do
    assignment = Assignment.new(classroom: classrooms(:teacher_class), due_date: 1.week.from_now)
    assert_not assignment.valid?
    assert assignment.errors[:title].any?
  end

  test "validates due_date presence" do
    assignment = Assignment.new(classroom: classrooms(:teacher_class), title: "Test")
    assert_not assignment.valid?
    assert assignment.errors[:due_date].any?
  end

  test "past_due? returns true for past assignments" do
    assignment = assignments(:homework_one)
    assignment.due_date = 1.day.ago
    assert assignment.past_due?
  end

  test "past_due? returns false for future assignments" do
    assignment = assignments(:homework_one)
    assert_not assignment.past_due?
  end

  test "teacher returns the classroom teacher" do
    assignment = assignments(:homework_one)
    assert_equal users(:admin), assignment.teacher
  end
end
