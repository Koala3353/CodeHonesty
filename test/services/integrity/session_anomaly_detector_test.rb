require "test_helper"

class Integrity::SessionAnomalyDetectorTest < ActiveSupport::TestCase
  test "detects no breaks in long session" do
    user = users(:regular_user)

    # Create a 5-hour continuous session (exceeds 4-hour threshold)
    base_time = 6.hours.ago.to_i
    (0..(5 * 60)).each do |minute|
      user.heartbeats.create!(
        time: base_time + (minute * 60),
        entity: "/test/file.rb",
        project: "test",
        language: "Ruby"
      )
    end

    detector = Integrity::SessionAnomalyDetector.new(user, user.heartbeats.order(:time))
    flags = detector.detect

    assert flags.any? { |f| f[:type] == :no_breaks }
  end

  test "does not flag session with breaks" do
    user = users(:regular_user)

    # Create a 2-hour session with breaks
    base_time = 4.hours.ago.to_i

    # First hour
    (0..60).each do |minute|
      user.heartbeats.create!(
        time: base_time + (minute * 60),
        entity: "/test/file.rb",
        project: "test",
        language: "Ruby"
      )
    end

    # Second hour (after a 30-minute break)
    (0..60).each do |minute|
      user.heartbeats.create!(
        time: base_time + 5400 + (minute * 60), # 90 minutes later
        entity: "/test/file.rb",
        project: "test",
        language: "Ruby"
      )
    end

    detector = Integrity::SessionAnomalyDetector.new(user, user.heartbeats.order(:time))
    flags = detector.detect

    assert_not flags.any? { |f| f[:type] == :no_breaks }
  end
end
