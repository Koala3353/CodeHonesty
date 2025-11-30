class CreateCodeSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :code_snapshots do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :file_path, null: false
      t.text :content
      t.string :content_hash, limit: 64
      t.integer :lines_of_code, default: 0
      t.datetime :captured_at, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :code_snapshots, :content_hash
  end
end
