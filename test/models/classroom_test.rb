require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "belongs to teacher" do
    classroom = classrooms(:teacher_class)
    assert_equal users(:admin), classroom.teacher
  end

  test "generates unique code on create" do
    teacher = users(:admin)
    classroom = Classroom.new(name: "New Class", teacher: teacher)
    assert classroom.save
    assert classroom.code.present?
    assert_equal 6, classroom.code.length
  end

  test "validates name presence" do
    classroom = Classroom.new(teacher: users(:admin))
    assert_not classroom.valid?
    assert classroom.errors[:name].any?
  end

  test "validates code uniqueness" do
    existing = classrooms(:teacher_class)
    classroom = Classroom.new(name: "Test", teacher: users(:admin), code: existing.code)
    assert_not classroom.valid?
    assert classroom.errors[:code].any?
  end

  test "has many students through enrollments" do
    classroom = classrooms(:teacher_class)
    assert_includes classroom.students, users(:regular_user)
    assert_includes classroom.students, users(:another_user)
  end

  test "has many assignments" do
    classroom = classrooms(:teacher_class)
    assert_includes classroom.assignments, assignments(:homework_one)
  end
end
