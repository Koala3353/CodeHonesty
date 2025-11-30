class Commit < ApplicationRecord
  belongs_to :repository
  belongs_to :user

  validates :sha, presence: true
  validates :sha, uniqueness: { scope: :repository_id }

  scope :recent, -> { order(committed_at: :desc) }

  def short_sha
    sha[0..6]
  end

  def github_url
    "#{repository.github_url}/commit/#{sha}"
  end
end
