class Heartbeat < ApplicationRecord
  include Heartbeatable

  belongs_to :user

  # Source types for heartbeats
  enum :source_type, {
    direct_entry: 0,    # From editor plugin
    wakapi_import: 1,   # Imported from WakaTime/Wakapi
    test_entry: 2       # Test data
  }, prefix: :source

  validates :time, presence: true
  validates :fields_hash, uniqueness: { scope: :user_id, allow_nil: true }

  before_validation :calculate_fields_hash, on: :create
  before_validation :sanitize_fields

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :coding, -> { where(category: [nil, "", "coding"]) }
  scope :for_project, ->(project) { where(project: project) }
  scope :for_language, ->(language) { where(language: language) }
  scope :for_editor, ->(editor) { where(editor: editor) }

  # Soft delete
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # Restore soft-deleted heartbeat
  def restore!
    update!(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  # Format time as human-readable
  def formatted_time
    Time.at(time).utc.iso8601
  end

  # Get user's timezone-aware time
  def local_time(timezone = nil)
    tz = TZInfo::Timezone.get(timezone || user.timezone || "UTC")
    tz.to_local(Time.at(time).utc)
  end

  private

  def calculate_fields_hash
    return if fields_hash.present?

    hash_data = [
      user_id,
      time,
      entity,
      project,
      language,
      editor,
      branch,
      is_write
    ].join("|")

    self.fields_hash = Digest::MD5.hexdigest(hash_data)
  end

  def sanitize_fields
    # Ensure UTF-8 encoding for string fields
    [:entity, :project, :language, :editor, :operating_system, :branch, :machine].each do |field|
      value = send(field)
      next unless value.is_a?(String)

      # Force UTF-8 and remove invalid characters
      send("#{field}=", value.encode("UTF-8", invalid: :replace, undef: :replace, replace: ""))
    end
  end
end
