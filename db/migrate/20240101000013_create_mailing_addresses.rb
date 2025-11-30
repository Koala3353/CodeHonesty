class CreateMailingAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :mailing_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :street_address
      t.string :street_address_2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.boolean :primary, default: false

      t.timestamps
    end

    add_index :mailing_addresses, [:user_id, :primary]
  end
end
