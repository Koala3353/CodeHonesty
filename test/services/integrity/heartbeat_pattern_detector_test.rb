require "test_helper"

class Integrity::HeartbeatPatternDetectorTest < ActiveSupport::TestCase
  test "detects regular intervals" do
    user = users(:regular_user)

    # Create heartbeats with suspiciously regular intervals
    base_time = 1.hour.ago.to_i
    20.times do |i|
      user.heartbeats.create!(
        time: base_time + (i * 30), # Exactly 30 seconds apart
        entity: "/test/file.rb",
        project: "test",
        language: "Ruby"
      )
    end

    detector = Integrity::HeartbeatPatternDetector.new(user, user.heartbeats.order(:time))
    flags = detector.detect

    assert flags.any? { |f| f[:type] == :regular_intervals }
  end

  test "does not flag irregular intervals" do
    user = users(:regular_user)

    # Create heartbeats with varied intervals
    base_time = 1.hour.ago.to_i
    intervals = [15, 45, 22, 67, 33, 89, 12, 55, 28, 71]
    current_time = base_time

    intervals.each do |interval|
      current_time += interval
      user.heartbeats.create!(
        time: current_time,
        entity: "/test/file.rb",
        project: "test",
        language: "Ruby"
      )
    end

    detector = Integrity::HeartbeatPatternDetector.new(user, user.heartbeats.order(:time))
    flags = detector.detect

    assert_not flags.any? { |f| f[:type] == :regular_intervals }
  end
end
