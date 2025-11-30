class SimilarityReport < ApplicationRecord
  belongs_to :submission
  belongs_to :compared_submission, class_name: "Submission"

  validates :submission_id, uniqueness: { scope: :compared_submission_id, message: "already has a comparison with this submission" }
  validates :similarity_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  scope :high_similarity, ->(threshold = 80) { where("similarity_score >= ?", threshold) }
  scope :by_similarity, -> { order(similarity_score: :desc) }

  # Check if similarity is concerning
  def concerning?(threshold = 80)
    similarity_score.present? && similarity_score >= threshold
  end

  # Get both submissions' students
  def students
    [submission.student, compared_submission.student]
  end
end
