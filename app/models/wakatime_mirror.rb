class WakatimeMirror < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true
  validates :endpoint, uniqueness: { scope: :user_id }
  validates :endpoint, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  def sync_heartbeat(heartbeat)
    return unless enabled?
    return if api_key_ciphertext.blank?

    # Queue job to sync heartbeat
    WakatimeMirrorSyncJob.perform_later(id, heartbeat.id)
  end
end
