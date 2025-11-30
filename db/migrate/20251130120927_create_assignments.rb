class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :classroom, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :due_date, null: false
      t.decimal :expected_hours, precision: 5, scale: 2

      t.timestamps
    end
  end
end
