class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.datetime :enrolled_at, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :enrollments, [ :classroom_id, :student_id ], unique: true
  end
end
