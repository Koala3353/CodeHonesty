require "test_helper"

class Integrity::AnalyzerTest < ActiveSupport::TestCase
  test "initializes with user" do
    user = users(:regular_user)
    analyzer = Integrity::Analyzer.new(user: user)

    assert_equal user, analyzer.user
    assert_nil analyzer.submission
  end

  test "initializes with submission" do
    submission = submissions(:user_submission)
    analyzer = Integrity::Analyzer.new(submission: submission)

    assert_equal submission.student, analyzer.user
    assert_equal submission, analyzer.submission
  end

  test "raises error without user or submission" do
    assert_raises ArgumentError do
      Integrity::Analyzer.new
    end
  end

  test "analyze returns array of flags" do
    user = users(:regular_user)
    analyzer = Integrity::Analyzer.new(user: user)

    flags = analyzer.analyze

    assert flags.is_a?(Array)
  end

  test "calculate_trust_score starts at 100" do
    user = users(:regular_user)
    analyzer = Integrity::Analyzer.new(user: user)
    analyzer.analyze

    score = analyzer.calculate_trust_score

    assert score <= 100
    assert score >= 0
  end

  test "calculate_trust_score decreases with flags" do
    user = users(:regular_user)
    analyzer = Integrity::Analyzer.new(user: user)

    # Manually add flags
    analyzer.instance_variable_get(:@flags) << { type: :test, severity: :high, description: "test", evidence: {} }
    analyzer.instance_variable_get(:@flags) << { type: :test, severity: :medium, description: "test", evidence: {} }

    score = analyzer.calculate_trust_score

    assert score < 100
    assert_equal 75, score # 100 - 15 (high) - 10 (medium)
  end
end
