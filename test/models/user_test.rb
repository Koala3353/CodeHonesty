require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should have valid trust levels" do
    user = users(:regular_user)
    assert user.trust_blue?
    assert user.can_appear_on_leaderboard?
  end

  test "convicted user cannot appear on leaderboard" do
    user = users(:regular_user)
    user.trust_level = :red
    assert user.trust_red?
    assert_not user.can_appear_on_leaderboard?
  end

  test "admin user has admin access" do
    admin = users(:admin)
    assert admin.admin?
  end

  test "regular user does not have admin access" do
    user = users(:regular_user)
    assert_not user.admin?
  end

  test "display_username returns username if present" do
    user = users(:regular_user)
    assert_equal "testuser", user.display_username
  end

  test "validates username format" do
    user = User.new(email: "test@test.com")
    user.username = "valid_username-123"
    assert user.valid?

    user.username = "invalid username!"
    assert_not user.valid?
    assert user.errors[:username].any?
  end
end
