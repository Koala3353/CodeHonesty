class ProjectRepoMapping < ApplicationRecord
  belongs_to :user
  belongs_to :repository, optional: true

  validates :project_name, presence: true
  validates :project_name, uniqueness: { scope: :user_id }

  scope :auto_mapped, -> { where(auto_mapped: true) }
  scope :manual, -> { where(auto_mapped: false) }
  scope :linked, -> { where.not(repository_id: nil) }
  scope :unlinked, -> { where(repository_id: nil) }
end
