class CreateSailorsLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :sailors_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :slack_channel_id
      t.string :slack_message_ts
      t.text :query
      t.text :response
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :sailors_logs, [:slack_channel_id, :slack_message_ts]
  end
end
