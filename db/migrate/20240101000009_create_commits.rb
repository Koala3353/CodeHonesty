class CreateCommits < ActiveRecord::Migration[8.1]
  def change
    create_table :commits do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :sha, null: false
      t.string :message
      t.string :author_name
      t.string :author_email
      t.datetime :committed_at

      t.timestamps
    end

    add_index :commits, [:repository_id, :sha], unique: true
  end
end
