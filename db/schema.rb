# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_01_01_000015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_api_keys_on_token", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "commits", force: :cascade do |t|
    t.string "author_email"
    t.string "author_name"
    t.datetime "committed_at"
    t.datetime "created_at", null: false
    t.string "message"
    t.bigint "repository_id", null: false
    t.string "sha", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["repository_id", "sha"], name: "index_commits_on_repository_id_and_sha", unique: true
    t.index ["repository_id"], name: "index_commits_on_repository_id"
    t.index ["user_id"], name: "index_commits_on_user_id"
  end

  create_table "email_addresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "primary", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "verified", default: false
    t.datetime "verified_at"
    t.index ["email"], name: "index_email_addresses_on_email", unique: true
    t.index ["user_id", "primary"], name: "index_email_addresses_on_user_id_and_primary"
    t.index ["user_id"], name: "index_email_addresses_on_user_id"
  end

  create_table "heartbeats", force: :cascade do |t|
    t.string "branch"
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "cursorpos"
    t.datetime "deleted_at"
    t.string "editor"
    t.string "entity"
    t.string "fields_hash"
    t.boolean "is_write", default: false
    t.string "language"
    t.integer "lineno"
    t.integer "lines"
    t.string "machine"
    t.string "operating_system"
    t.string "project"
    t.integer "source_type", default: 0
    t.bigint "time", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["fields_hash"], name: "index_heartbeats_on_fields_hash"
    t.index ["time"], name: "index_heartbeats_on_time"
    t.index ["user_id", "project", "time"], name: "index_heartbeats_on_user_id_and_project_and_time"
    t.index ["user_id", "time"], name: "index_heartbeats_on_user_id_and_time"
    t.index ["user_id"], name: "index_heartbeats_on_user_id"
  end

  create_table "leaderboard_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "leaderboard_id", null: false
    t.integer "rank"
    t.integer "streak_count", default: 0
    t.integer "total_seconds", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["leaderboard_id", "rank"], name: "index_leaderboard_entries_on_leaderboard_id_and_rank"
    t.index ["leaderboard_id", "user_id"], name: "index_leaderboard_entries_on_leaderboard_id_and_user_id", unique: true
    t.index ["leaderboard_id"], name: "index_leaderboard_entries_on_leaderboard_id"
    t.index ["user_id"], name: "index_leaderboard_entries_on_user_id"
  end

  create_table "leaderboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "finished_generating_at"
    t.integer "period_type", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date", "period_type"], name: "index_leaderboards_on_start_date_and_period_type", unique: true
  end

  create_table "mailing_addresses", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "postal_code"
    t.boolean "primary", default: false
    t.string "state"
    t.string "street_address"
    t.string "street_address_2"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "primary"], name: "index_mailing_addresses_on_user_id_and_primary"
    t.index ["user_id"], name: "index_mailing_addresses_on_user_id"
  end

  create_table "physical_mails", force: :cascade do |t|
    t.string "carrier"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.text "description"
    t.bigint "mailing_address_id", null: false
    t.datetime "shipped_at"
    t.string "status"
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["mailing_address_id"], name: "index_physical_mails_on_mailing_address_id"
    t.index ["user_id"], name: "index_physical_mails_on_user_id"
  end

  create_table "project_repo_mappings", force: :cascade do |t|
    t.boolean "auto_mapped", default: false
    t.datetime "created_at", null: false
    t.string "project_name", null: false
    t.bigint "repository_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["repository_id"], name: "index_project_repo_mappings_on_repository_id"
    t.index ["user_id", "project_name"], name: "index_project_repo_mappings_on_user_id_and_project_name", unique: true
    t.index ["user_id"], name: "index_project_repo_mappings_on_user_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_branch"
    t.text "description"
    t.string "full_name", null: false
    t.string "github_id"
    t.string "language"
    t.string "name", null: false
    t.boolean "private", default: false
    t.datetime "pushed_at"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id", null: false
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
    t.index ["user_id", "full_name"], name: "index_repositories_on_user_id_and_full_name"
    t.index ["user_id"], name: "index_repositories_on_user_id"
  end

  create_table "sailors_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "query"
    t.text "response"
    t.string "slack_channel_id"
    t.string "slack_message_ts"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["slack_channel_id", "slack_message_ts"], name: "index_sailors_logs_on_slack_channel_id_and_slack_message_ts"
    t.index ["user_id"], name: "index_sailors_logs_on_user_id"
  end

  create_table "sign_in_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_sign_in_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_sign_in_tokens_on_user_id"
  end

  create_table "trust_level_audit_logs", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.datetime "created_at", null: false
    t.integer "new_trust_level"
    t.integer "old_trust_level"
    t.text "reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["admin_id"], name: "index_trust_level_audit_logs_on_admin_id"
    t.index ["user_id"], name: "index_trust_level_audit_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "admin_level", default: 0
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "github_access_token_ciphertext"
    t.string "github_uid"
    t.string "slack_access_token_ciphertext"
    t.string "slack_uid"
    t.string "timezone", default: "UTC"
    t.integer "trust_level", default: 0
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email"
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true
    t.index ["slack_uid"], name: "index_users_on_slack_uid", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "wakatime_mirrors", force: :cascade do |t|
    t.string "api_key_ciphertext"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.string "endpoint", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "endpoint"], name: "index_wakatime_mirrors_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_wakatime_mirrors_on_user_id"
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "commits", "repositories"
  add_foreign_key "commits", "users"
  add_foreign_key "email_addresses", "users"
  add_foreign_key "heartbeats", "users"
  add_foreign_key "leaderboard_entries", "leaderboards"
  add_foreign_key "leaderboard_entries", "users"
  add_foreign_key "mailing_addresses", "users"
  add_foreign_key "physical_mails", "mailing_addresses"
  add_foreign_key "physical_mails", "users"
  add_foreign_key "project_repo_mappings", "repositories"
  add_foreign_key "project_repo_mappings", "users"
  add_foreign_key "repositories", "users"
  add_foreign_key "sailors_logs", "users"
  add_foreign_key "sign_in_tokens", "users"
  add_foreign_key "trust_level_audit_logs", "users"
  add_foreign_key "trust_level_audit_logs", "users", column: "admin_id"
  add_foreign_key "wakatime_mirrors", "users"
end
