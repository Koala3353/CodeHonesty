# Job to analyze a submission for integrity issues
class AnalyzeSubmissionJob < ApplicationJob
  queue_as QUEUES[:latency_5m]

  def perform(submission_id)
    submission = Submission.find_by(id: submission_id)
    return unless submission

    Rails.logger.info "Analyzing submission #{submission_id} for integrity issues"

    # Run integrity analysis
    analyzer = Integrity::Analyzer.new(submission: submission)
    flags = analyzer.analyze_and_save!

    Rails.logger.info "Found #{flags.count} flags for submission #{submission_id}"

    # Update submission status if flags were found
    if flags.any? { |f| f.severity_high? || f.severity_critical? }
      submission.update!(status: :flagged)
    end

    # Compare with other submissions
    compare_with_other_submissions(submission)
  rescue StandardError => e
    Rails.logger.error "Error analyzing submission #{submission_id}: #{e.message}"
    raise
  end

  private

  def compare_with_other_submissions(submission)
    other_submissions = submission.assignment.submissions
                                 .where.not(id: submission.id)
                                 .where.not(status: :pending)

    other_submissions.find_each do |other|
      # Skip if already compared
      next if SimilarityReport.exists?(
        submission: submission,
        compared_submission: other
      )

      calculator = Integrity::SimilarityCalculator.new(submission, other)
      calculator.calculate_and_save!
    rescue StandardError => e
      Rails.logger.error "Error comparing submissions #{submission.id} and #{other.id}: #{e.message}"
    end
  end
end
