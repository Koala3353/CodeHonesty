class Flag < ApplicationRecord
  belongs_to :submission, optional: true
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :flag_type, {
    fake_time: "fake_time",
    plagiarism: "plagiarism",
    pattern_anomaly: "pattern_anomaly",
    copy_paste: "copy_paste",
    regular_intervals: "regular_intervals",
    impossible_speed: "impossible_speed",
    geographic_impossibility: "geographic_impossibility",
    no_breaks: "no_breaks",
    perfect_duration: "perfect_duration",
    code_similarity: "code_similarity"
  }, prefix: :type

  enum :severity, {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }, prefix: :severity

  enum :status, {
    pending: 0,
    reviewed: 1,
    dismissed: 2,
    confirmed: 3
  }, prefix: :status

  validates :flag_type, presence: true

  scope :pending, -> { status_pending }
  scope :confirmed, -> { status_confirmed }
  scope :by_severity, -> { order(severity: :desc) }

  # Mark flag as reviewed
  def review!(reviewer, status, notes = nil)
    update!(
      reviewed_by: reviewer,
      reviewed_at: Time.current,
      status: status,
      description: notes.present? ? "#{description}\n\nReview notes: #{notes}" : description
    )
  end

  # Confirm the flag
  def confirm!(reviewer, notes = nil)
    review!(reviewer, :confirmed, notes)
  end

  # Dismiss the flag
  def dismiss!(reviewer, notes = nil)
    review!(reviewer, :dismissed, notes)
  end
end
