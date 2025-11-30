class CreatePhysicalMails < ActiveRecord::Migration[8.1]
  def change
    create_table :physical_mails do |t|
      t.references :user, null: false, foreign_key: true
      t.references :mailing_address, null: false, foreign_key: true
      t.string :tracking_number
      t.string :carrier
      t.string :status
      t.text :description
      t.datetime :shipped_at
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
