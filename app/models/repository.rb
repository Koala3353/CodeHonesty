class Repository < ApplicationRecord
  belongs_to :user
  has_many :commits, dependent: :destroy
  has_many :project_repo_mappings, dependent: :nullify

  validates :name, presence: true
  validates :full_name, presence: true
  validates :github_id, uniqueness: { allow_nil: true }

  scope :public_repos, -> { where(private: false) }
  scope :private_repos, -> { where(private: true) }

  def github_url
    "https://github.com/#{full_name}"
  end

  def clone_url
    "#{github_url}.git"
  end
end
