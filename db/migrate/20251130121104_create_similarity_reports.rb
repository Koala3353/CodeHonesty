class CreateSimilarityReports < ActiveRecord::Migration[8.1]
  def change
    create_table :similarity_reports do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :compared_submission, null: false, foreign_key: { to_table: :submissions }
      t.decimal :similarity_score, precision: 5, scale: 2, default: 0.0
      t.integer :matched_lines, default: 0
      t.jsonb :report_data, default: {}

      t.timestamps
    end

    add_index :similarity_reports, [ :submission_id, :compared_submission_id ], unique: true, name: "idx_similarity_reports_unique"
  end
end
