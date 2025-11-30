class CreateProjectRepoMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :project_repo_mappings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :repository, foreign_key: true
      t.string :project_name, null: false
      t.boolean :auto_mapped, default: false

      t.timestamps
    end

    add_index :project_repo_mappings, [:user_id, :project_name], unique: true
  end
end
