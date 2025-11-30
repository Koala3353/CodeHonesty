class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :slack_uid, index: { unique: true }
      t.string :github_uid, index: { unique: true }
      t.string :username, index: { unique: true }
      t.string :email
      t.string :display_name
      t.string :avatar_url
      t.string :timezone, default: "UTC"
      t.integer :trust_level, default: 0
      t.integer :admin_level, default: 0
      t.string :slack_access_token_ciphertext
      t.string :github_access_token_ciphertext

      t.timestamps
    end

    add_index :users, :email
  end
end
