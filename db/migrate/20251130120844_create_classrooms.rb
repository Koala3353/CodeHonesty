class CreateClassrooms < ActiveRecord::Migration[8.1]
  def change
    create_table :classrooms do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.references :teacher, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :classrooms, :code, unique: true
  end
end
