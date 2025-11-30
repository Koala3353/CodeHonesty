class CreateSignInTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :sign_in_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
  end
end
