class LeaderboardBuilder
  attr_reader :leaderboard

  def initialize(leaderboard)
    @leaderboard = leaderboard
  end

  def build!
    ActiveRecord::Base.transaction do
      # Clear existing entries
      leaderboard.leaderboard_entries.delete_all

      # Get all eligible users
      users = eligible_users

      # Calculate duration and streak for each user
      user_data = calculate_user_data(users)

      # Sort by duration and assign ranks
      ranked_data = rank_users(user_data)

      # Bulk insert entries
      create_entries(ranked_data)

      # Mark as finished
      leaderboard.mark_finished!
    end

    leaderboard
  end

  private

  def eligible_users
    # Only include users who:
    # - Have linked GitHub (for verification)
    # - Are not convicted (red trust level)
    User.where.not(github_uid: nil)
        .where.not(trust_level: :red)
  end

  def calculate_user_data(users)
    date_range = leaderboard.date_range

    users.map do |user|
      heartbeats = user.heartbeats.in_time_range(
        date_range.begin,
        date_range.end
      ).active.coding

      duration = heartbeats.calculate_duration
      streak = user.streak_count

      {
        user: user,
        total_seconds: duration,
        streak_count: streak
      }
    end.select { |data| data[:total_seconds] > 0 }
  end

  def rank_users(user_data)
    sorted = user_data.sort_by { |data| -data[:total_seconds] }

    sorted.each_with_index.map do |data, index|
      data.merge(rank: index + 1)
    end
  end

  def create_entries(ranked_data)
    return if ranked_data.empty?

    entries = ranked_data.map do |data|
      {
        leaderboard_id: leaderboard.id,
        user_id: data[:user].id,
        total_seconds: data[:total_seconds],
        rank: data[:rank],
        streak_count: data[:streak_count],
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    LeaderboardEntry.insert_all(entries)
  end
end
