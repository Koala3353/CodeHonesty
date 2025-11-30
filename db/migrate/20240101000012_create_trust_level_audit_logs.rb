class CreateTrustLevelAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :trust_level_audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.integer :old_trust_level
      t.integer :new_trust_level
      t.text :reason

      t.timestamps
    end
  end
end
