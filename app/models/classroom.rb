class Classroom < ApplicationRecord
  belongs_to :teacher, class_name: "User"
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :assignments, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, length: { maximum: 10 }

  before_validation :generate_code, on: :create

  # Get all submissions for this classroom
  def submissions
    Submission.joins(:assignment).where(assignments: { classroom_id: id })
  end

  # Get all flags for this classroom
  def flags
    Flag.joins(submission: :assignment).where(assignments: { classroom_id: id })
  end

  private

  def generate_code
    return if code.present?
    loop do
      self.code = SecureRandom.alphanumeric(6).upcase
      break unless Classroom.exists?(code: code)
    end
  end
end
