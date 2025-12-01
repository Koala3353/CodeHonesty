class Assignment < ApplicationRecord
  belongs_to :classroom
  has_many :submissions, dependent: :destroy

  validates :title, presence: true
  validates :due_date, presence: true
  validates :expected_hours, numericality: { greater_than: 0 }, allow_nil: true

  # Get the teacher for this assignment
  def teacher
    classroom.teacher
  end

  # Check if assignment is past due
  def past_due?
    due_date < Time.current
  end

  # Get all flags for this assignment
  def flags
    Flag.joins(:submission).where(submissions: { assignment_id: id })
  end

  # Get average trust score for all submissions
  def average_trust_score
    submissions.where.not(trust_score: nil).average(:trust_score)
  end

  # Get flagged submissions count
  def flagged_count
    submissions.where(status: :flagged).count
  end
end
