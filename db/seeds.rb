# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create a test admin user (only in development/test)
if Rails.env.development? || Rails.env.test?
  admin = User.find_or_create_by!(email: "admin@example.com") do |u|
    u.username = "admin"
    u.display_name = "Admin User"
    u.admin_level = :superadmin
    u.trust_level = :green
    u.timezone = "UTC"
  end

  puts "Created admin user: #{admin.email}"

  # Create an API key for the admin
  api_key = admin.api_keys.find_or_create_by!(name: "Development Key") do |k|
    k.token = "dev-api-key-12345"
  end

  puts "Admin API Key: #{api_key.token}"

  # Create some test users
  5.times do |i|
    user = User.find_or_create_by!(email: "user#{i + 1}@example.com") do |u|
      u.username = "testuser#{i + 1}"
      u.display_name = "Test User #{i + 1}"
      u.timezone = "UTC"
    end

    # Create API key for each user
    user.api_keys.find_or_create_by!(name: "Default Key")

    # Create some heartbeats for each user
    languages = %w[Ruby JavaScript Python TypeScript Go Rust]
    projects = ["hackatime", "my-app", "cool-project", "open-source"]
    editors = ["VS Code", "Vim", "JetBrains", "Sublime Text"]

    50.times do |j|
      time = (7.days.ago + rand(7.days)).to_i

      user.heartbeats.create!(
        time: time,
        entity: "/path/to/file#{j}.rb",
        project: projects.sample,
        language: languages.sample,
        editor: editors.sample,
        operating_system: %w[macOS Windows Linux].sample,
        branch: "main",
        source_type: :test_entry
      )
    end

    puts "Created user: #{user.email} with #{user.heartbeats.count} heartbeats"
  end

  # Create initial leaderboards
  Leaderboard.find_or_create_by!(start_date: Date.current, period_type: :daily)
  Leaderboard.find_or_create_by!(start_date: Date.current, period_type: :last_7_days)

  puts "Created leaderboards"
end

puts "Seeding complete!"
