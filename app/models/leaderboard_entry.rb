class LeaderboardEntry < ApplicationRecord
  belongs_to :leaderboard
  belongs_to :user

  validates :leaderboard_id, uniqueness: { scope: :user_id }

  scope :ranked, -> { order(rank: :asc) }
  scope :top, ->(n) { ranked.limit(n) }

  def duration_formatted
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60

    if hours > 0
      "#{hours}h #{minutes}m"
    elsif minutes > 0
      "#{minutes}m #{seconds}s"
    else
      "#{seconds}s"
    end
  end
end
