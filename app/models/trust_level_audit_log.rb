class TrustLevelAuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :admin, class_name: "User"

  validates :old_trust_level, presence: true
  validates :new_trust_level, presence: true

  # Get the trust level names
  def old_trust_level_name
    User.trust_levels.key(old_trust_level)
  end

  def new_trust_level_name
    User.trust_levels.key(new_trust_level)
  end
end
