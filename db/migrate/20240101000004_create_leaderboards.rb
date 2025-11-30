class CreateLeaderboards < ActiveRecord::Migration[8.1]
  def change
    create_table :leaderboards do |t|
      t.date :start_date, null: false
      t.integer :period_type, null: false
      t.datetime :finished_generating_at

      t.timestamps
    end

    add_index :leaderboards, [:start_date, :period_type], unique: true
  end
end
