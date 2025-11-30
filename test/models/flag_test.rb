require "test_helper"

class FlagTest < ActiveSupport::TestCase
  test "belongs to user" do
    flag = flags(:copy_paste_flag)
    assert_equal users(:regular_user), flag.user
  end

  test "belongs to submission" do
    flag = flags(:copy_paste_flag)
    assert_equal submissions(:user_submission), flag.submission
  end

  test "validates flag_type presence" do
    flag = Flag.new(user: users(:regular_user))
    assert_not flag.valid?
    assert flag.errors[:flag_type].any?
  end

  test "severity enum works" do
    flag = flags(:copy_paste_flag)
    assert flag.severity_high?
    assert_not flag.severity_low?
    assert_not flag.severity_critical?
  end

  test "status enum works" do
    flag = flags(:copy_paste_flag)
    assert flag.status_pending?
    assert_not flag.status_confirmed?
  end

  test "confirm! marks flag as confirmed" do
    flag = flags(:copy_paste_flag)
    reviewer = users(:admin)

    flag.confirm!(reviewer, "Confirmed after review")

    assert flag.status_confirmed?
    assert_equal reviewer, flag.reviewed_by
    assert flag.reviewed_at.present?
  end

  test "dismiss! marks flag as dismissed" do
    flag = flags(:copy_paste_flag)
    reviewer = users(:admin)

    flag.dismiss!(reviewer, "False positive")

    assert flag.status_dismissed?
    assert_equal reviewer, flag.reviewed_by
    assert flag.reviewed_at.present?
  end
end
