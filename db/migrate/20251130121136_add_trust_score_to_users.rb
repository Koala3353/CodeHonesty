class AddTrustScoreToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :trust_score, :decimal, precision: 5, scale: 2, default: 100.0
  end
end
