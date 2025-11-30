class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :github_id, index: { unique: true }
      t.string :name, null: false
      t.string :full_name, null: false
      t.string :url
      t.string :default_branch
      t.boolean :private, default: false
      t.string :language
      t.text :description
      t.datetime :pushed_at

      t.timestamps
    end

    add_index :repositories, [:user_id, :full_name]
  end
end
