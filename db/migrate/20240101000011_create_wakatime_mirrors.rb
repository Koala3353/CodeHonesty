class CreateWakatimeMirrors < ActiveRecord::Migration[8.1]
  def change
    create_table :wakatime_mirrors do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :api_key_ciphertext
      t.boolean :enabled, default: true

      t.timestamps
    end

    add_index :wakatime_mirrors, [:user_id, :endpoint], unique: true
  end
end
