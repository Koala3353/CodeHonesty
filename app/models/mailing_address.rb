class MailingAddress < ApplicationRecord
  belongs_to :user
  has_many :physical_mails, dependent: :nullify

  validates :name, presence: true
  validates :street_address, presence: true
  validates :city, presence: true
  validates :country, presence: true

  scope :primary, -> { where(primary: true) }

  def full_address
    [
      name,
      street_address,
      street_address_2,
      "#{city}, #{state} #{postal_code}",
      country
    ].compact_blank.join("\n")
  end

  def make_primary!
    transaction do
      user.mailing_addresses.update_all(primary: false)
      update!(primary: true)
    end
  end
end
