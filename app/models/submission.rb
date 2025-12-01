class Submission < ApplicationRecord
  belongs_to :assignment
  belongs_to :student, class_name: "User"
  has_many :flags, dependent: :destroy
  has_many :code_snapshots, dependent: :destroy
  has_many :similarity_reports, dependent: :destroy
  has_many :compared_similarity_reports, class_name: "SimilarityReport", foreign_key: "compared_submission_id", dependent: :destroy

  enum :status, {
    pending: 0,
    submitted: 1,
    flagged: 2,
    approved: 3
  }, prefix: :status

  validates :assignment_id, uniqueness: { scope: :student_id, message: "already has a submission for this assignment" }

  before_create :set_default_trust_score

  # Get the classroom for this submission
  def classroom
    assignment.classroom
  end

  # Get heartbeats for this submission's project
  def heartbeats
    return Heartbeat.none unless project_name.present?
    student.heartbeats.where(project: project_name)
  end

  # Calculate coding duration from heartbeats
  def calculate_coding_time
    return 0 unless project_name.present?
    heartbeats.calculate_duration
  end

  # Update total coding time
  def update_coding_time!
    update!(total_coding_time: calculate_coding_time)
  end

  # Check if submission is flagged
  def flagged?
    status_flagged? || flags.pending.exists?
  end

  # Get highest severity flag
  def highest_severity_flag
    flags.order(severity: :desc).first
  end

  private

  def set_default_trust_score
    self.trust_score ||= 100.0
  end
end
