class CreateEmailAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :email_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.boolean :primary, default: false
      t.boolean :verified, default: false
      t.datetime :verified_at

      t.timestamps
    end

    add_index :email_addresses, :email, unique: true
    add_index :email_addresses, [:user_id, :primary]
  end
end
