class CreateFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :flags do |t|
      t.references :submission, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :flag_type, null: false
      t.integer :severity, default: 1
      t.text :description
      t.jsonb :evidence, default: {}
      t.integer :status, default: 0
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end
  end
end
