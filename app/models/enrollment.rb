class Enrollment < ApplicationRecord
  belongs_to :classroom
  belongs_to :student, class_name: "User"

  validates :classroom_id, uniqueness: { scope: :student_id, message: "student already enrolled in this classroom" }

  before_create :set_enrolled_at

  private

  def set_enrolled_at
    self.enrolled_at ||= Time.current
  end
end
