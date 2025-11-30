class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  has_many :heartbeats, dependent: :destroy
  has_many :leaderboard_entries, dependent: :destroy
  has_many :email_addresses, dependent: :destroy
  has_many :sign_in_tokens, dependent: :destroy
  has_many :repositories, dependent: :destroy
  has_many :commits, dependent: :destroy
  has_many :project_repo_mappings, dependent: :destroy
  has_many :wakatime_mirrors, dependent: :destroy
  has_many :trust_level_audit_logs, dependent: :destroy
  has_many :mailing_addresses, dependent: :destroy
  has_many :physical_mails, dependent: :destroy
  has_many :sailors_logs, dependent: :destroy

  # Trust levels for moderation
  enum :trust_level, {
    blue: 0,    # Unscored (default)
    red: 1,     # Convicted (banned from leaderboards)
    green: 2,   # Trusted
    yellow: 3   # Suspected (hidden from user)
  }, prefix: :trust

  # Admin levels for permissions
  enum :admin_level, {
    default: 0,    # Regular user
    superadmin: 1, # Full access
    admin: 2,      # Moderation access
    viewer: 3      # Read-only admin
  }, prefix: :admin

  validates :username, uniqueness: { allow_nil: true }, format: { with: /\A[a-zA-Z0-9_-]+\z/, message: "can only contain letters, numbers, underscores, and dashes", allow_nil: true }
  validates :slack_uid, uniqueness: { allow_nil: true }
  validates :github_uid, uniqueness: { allow_nil: true }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone::MAPPING.keys + ActiveSupport::TimeZone::MAPPING.values, allow_blank: true }

  before_create :generate_username

  # Find or create user from Slack OAuth
  def self.find_or_create_from_slack(auth)
    user = find_by(slack_uid: auth.uid)
    return user if user

    user = find_by(email: auth.info.email) if auth.info.email.present?

    if user
      user.update!(
        slack_uid: auth.uid,
        avatar_url: auth.info.image,
        slack_access_token_ciphertext: auth.credentials.token
      )
    else
      user = create!(
        slack_uid: auth.uid,
        email: auth.info.email,
        display_name: auth.info.name,
        avatar_url: auth.info.image,
        slack_access_token_ciphertext: auth.credentials.token
      )
    end

    user
  end

  # Find or create user from GitHub OAuth
  def self.find_or_create_from_github(auth, current_user = nil)
    user = find_by(github_uid: auth.uid)

    if user && current_user && user != current_user
      raise "GitHub account already linked to another user"
    end

    if current_user
      current_user.update!(
        github_uid: auth.uid,
        github_access_token_ciphertext: auth.credentials.token
      )
      return current_user
    end

    return user if user

    user = find_by(email: auth.info.email) if auth.info.email.present?

    if user
      user.update!(
        github_uid: auth.uid,
        avatar_url: user.avatar_url || auth.info.image,
        github_access_token_ciphertext: auth.credentials.token
      )
    else
      user = create!(
        github_uid: auth.uid,
        email: auth.info.email,
        display_name: auth.info.name || auth.info.nickname,
        avatar_url: auth.info.image,
        github_access_token_ciphertext: auth.credentials.token
      )
    end

    user
  end

  def display_username
    username || display_name || email&.split("@")&.first || "Anonymous"
  end

  def today_heartbeats(timezone = self.timezone || "UTC")
    heartbeats.today(timezone)
  end

  def today_duration(timezone = self.timezone || "UTC")
    today_heartbeats(timezone).calculate_duration
  end

  def streak_count
    calculate_streak
  end

  def admin?
    admin_superadmin? || admin_admin?
  end

  def can_appear_on_leaderboard?
    !trust_red?
  end

  private

  def generate_username
    return if username.present?
    base = display_name&.parameterize&.underscore || email&.split("@")&.first&.parameterize&.underscore || "user"
    self.username = base
    counter = 1
    while User.exists?(username: self.username)
      self.username = "#{base}#{counter}"
      counter += 1
    end
  end

  def calculate_streak
    # Calculate consecutive days with at least 15 minutes of coding
    tz = TZInfo::Timezone.get(timezone || "UTC")
    today = tz.now.to_date
    streak = 0

    (0..365).each do |days_ago|
      date = today - days_ago
      duration = heartbeats.on_date(date, timezone || "UTC").calculate_duration

      if duration >= 15 * 60 # 15 minutes
        streak += 1
      elsif days_ago > 0 # Don't break streak if today has no activity yet
        break
      end
    end

    streak
  end
end
