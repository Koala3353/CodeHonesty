class EmailAddress < ApplicationRecord
  belongs_to :user

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :verified, -> { where(verified: true) }
  scope :primary, -> { where(primary: true) }

  def verify!
    update!(verified: true, verified_at: Time.current)
  end

  def make_primary!
    transaction do
      user.email_addresses.update_all(primary: false)
      update!(primary: true)
      user.update!(email: email)
    end
  end
end
