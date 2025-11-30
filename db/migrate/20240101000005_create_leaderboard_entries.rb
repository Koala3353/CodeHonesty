class CreateLeaderboardEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :leaderboard_entries do |t|
      t.references :leaderboard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :total_seconds, default: 0
      t.integer :rank
      t.integer :streak_count, default: 0

      t.timestamps
    end

    add_index :leaderboard_entries, [:leaderboard_id, :user_id], unique: true
    add_index :leaderboard_entries, [:leaderboard_id, :rank]
  end
end
