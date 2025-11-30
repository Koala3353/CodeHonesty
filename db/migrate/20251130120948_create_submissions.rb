class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.string :project_name
      t.datetime :submitted_at
      t.integer :status, default: 0
      t.decimal :trust_score, precision: 5, scale: 2
      t.integer :total_coding_time, default: 0

      t.timestamps
    end

    add_index :submissions, [:assignment_id, :student_id], unique: true
  end
end
