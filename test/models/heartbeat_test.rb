require "test_helper"

class HeartbeatTest < ActiveSupport::TestCase
  test "belongs to user" do
    heartbeat = heartbeats(:recent_heartbeat)
    assert_equal users(:regular_user), heartbeat.user
  end

  test "calculates fields hash on create" do
    user = users(:regular_user)
    heartbeat = user.heartbeats.create!(
      time: Time.current.to_i,
      entity: "/test/file.rb",
      project: "test",
      language: "Ruby"
    )
    assert heartbeat.fields_hash.present?
  end

  test "prevents duplicate heartbeats" do
    user = users(:regular_user)
    time = Time.current.to_i

    heartbeat1 = user.heartbeats.create!(
      time: time,
      entity: "/test/file.rb",
      project: "test",
      language: "Ruby"
    )

    # Same data should fail
    heartbeat2 = user.heartbeats.new(
      time: time,
      entity: "/test/file.rb",
      project: "test",
      language: "Ruby"
    )

    assert_not heartbeat2.valid?
    assert heartbeat2.errors[:fields_hash].any?
  end

  test "soft delete works" do
    heartbeat = heartbeats(:recent_heartbeat)
    assert_nil heartbeat.deleted_at
    assert_not heartbeat.deleted?

    heartbeat.soft_delete!
    assert heartbeat.deleted_at.present?
    assert heartbeat.deleted?
  end
end
