class Leaderboard < ApplicationRecord
  has_many :leaderboard_entries, dependent: :destroy
  has_many :users, through: :leaderboard_entries

  enum :period_type, {
    daily: 0,
    last_7_days: 1
  }

  validates :start_date, presence: true
  validates :period_type, presence: true
  validates :start_date, uniqueness: { scope: :period_type }

  scope :finished, -> { where.not(finished_generating_at: nil) }
  scope :pending, -> { where(finished_generating_at: nil) }

  def finished?
    finished_generating_at.present?
  end

  def mark_finished!
    update!(finished_generating_at: Time.current)
  end

  def date_range
    case period_type
    when "daily"
      start_date.beginning_of_day..start_date.end_of_day
    when "last_7_days"
      (start_date - 6.days).beginning_of_day..start_date.end_of_day
    else
      start_date.beginning_of_day..start_date.end_of_day
    end
  end

  def ranked_entries
    leaderboard_entries.includes(:user).order(rank: :asc)
  end

  def self.for_date(date, period_type: :daily)
    find_or_create_by!(start_date: date, period_type: period_type)
  end
end
