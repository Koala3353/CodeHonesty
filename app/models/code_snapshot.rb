class CodeSnapshot < ApplicationRecord
  belongs_to :submission

  validates :file_path, presence: true

  before_save :calculate_hash
  before_save :calculate_lines

  # Calculate SHA-256 hash of content
  def calculate_hash
    return unless content.present?
    self.content_hash = Digest::SHA256.hexdigest(content)
  end

  # Calculate lines of code (non-empty, non-comment lines)
  def calculate_lines
    return unless content.present?
    lines = content.lines.reject { |line| line.strip.empty? || line.strip.start_with?("//", "#", "/*", "*") }
    self.lines_of_code = lines.count
  end

  # Find similar snapshots
  def find_similar(threshold: 80)
    return CodeSnapshot.none unless content_hash.present?

    CodeSnapshot
      .where.not(id: id)
      .where(content_hash: content_hash)
  end
end
