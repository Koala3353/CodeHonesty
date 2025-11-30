class CreateHeartbeats < ActiveRecord::Migration[8.1]
  def change
    create_table :heartbeats do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :time, null: false
      t.string :entity
      t.string :project
      t.string :language
      t.string :editor
      t.string :operating_system
      t.string :branch
      t.string :machine
      t.string :category
      t.boolean :is_write, default: false
      t.integer :lines
      t.integer :lineno
      t.integer :cursorpos
      t.integer :source_type, default: 0
      t.string :fields_hash
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :heartbeats, [:user_id, :time]
    add_index :heartbeats, [:user_id, :project, :time]
    add_index :heartbeats, :fields_hash
    add_index :heartbeats, :time
  end
end
