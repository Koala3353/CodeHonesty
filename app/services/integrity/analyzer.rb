# Main integrity analyzer that runs all detection algorithms
class Integrity::Analyzer
  SEVERITY_WEIGHTS = {
    critical: 25,
    high: 15,
    medium: 10,
    low: 5
  }.freeze

  attr_reader :user, :submission, :flags

  def initialize(user: nil, submission: nil)
    @user = user || submission&.student
    @submission = submission
    @flags = []

    raise ArgumentError, "Must provide either user or submission" unless @user
  end

  def analyze
    heartbeats = get_heartbeats

    # Run all detectors
    run_detector(Integrity::HeartbeatPatternDetector, heartbeats)
    run_detector(Integrity::SessionAnomalyDetector, heartbeats)
    run_detector(Integrity::GeographicDetector, heartbeats)
    run_detector(Integrity::CopyPasteDetector, heartbeats)

    # Run similarity analysis if submission is provided
    analyze_similarity if @submission

    @flags
  end

  def analyze_and_save!
    analyze

    saved_flags = @flags.map do |flag_data|
      Flag.create!(
        user: @user,
        submission: @submission,
        flag_type: flag_data[:type],
        severity: flag_data[:severity],
        description: flag_data[:description],
        evidence: flag_data[:evidence],
        status: :pending
      )
    end

    # Update submission trust score if applicable
    update_submission_trust_score if @submission

    # Update user trust score
    @user.calculate_trust_score!

    saved_flags
  end

  def calculate_trust_score
    base_score = 100.0

    @flags.each do |flag|
      weight = SEVERITY_WEIGHTS[flag[:severity].to_sym] || 5
      base_score -= weight
    end

    [ [ base_score, 0 ].max, 100 ].min
  end

  private

  def get_heartbeats
    if @submission&.project_name.present?
      @user.heartbeats.where(project: @submission.project_name).order(:time)
    else
      @user.heartbeats.order(:time)
    end
  end

  def run_detector(detector_class, heartbeats)
    detector = detector_class.new(@user, heartbeats)
    detector_flags = detector.detect
    @flags.concat(detector_flags) if detector_flags.present?
  rescue StandardError => e
    Rails.logger.error("Detector #{detector_class} failed: #{e.message}")
  end

  def analyze_similarity
    return unless @submission.assignment

    # Compare with other submissions in the same assignment
    other_submissions = @submission.assignment.submissions
                                  .where.not(id: @submission.id)
                                  .where.not(status: :pending)

    other_submissions.find_each do |other|
      calculator = Integrity::SimilarityCalculator.new(@submission, other)
      result = calculator.calculate

      next unless result && result[:overall] >= Integrity::SimilarityCalculator::SIMILARITY_THRESHOLD

      @flags << {
        type: :code_similarity,
        severity: result[:overall] >= 90 ? :critical : :high,
        description: "Code similarity of #{result[:overall]}% with submission by #{other.student.display_username}",
        evidence: {
          similarity_score: result[:overall],
          compared_submission_id: other.id,
          compared_student: other.student.display_username,
          matched_files: result[:matched_files]
        }
      }
    end
  end

  def update_submission_trust_score
    @submission.update!(trust_score: calculate_trust_score)
  end
end
