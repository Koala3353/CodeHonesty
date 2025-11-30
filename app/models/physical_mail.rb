class PhysicalMail < ApplicationRecord
  belongs_to :user
  belongs_to :mailing_address

  STATUSES = %w[pending shipped in_transit delivered returned].freeze

  validates :status, inclusion: { in: STATUSES, allow_nil: true }

  scope :pending, -> { where(status: "pending") }
  scope :shipped, -> { where(status: "shipped") }
  scope :delivered, -> { where(status: "delivered") }

  def ship!(tracking_number: nil, carrier: nil)
    update!(
      status: "shipped",
      shipped_at: Time.current,
      tracking_number: tracking_number,
      carrier: carrier
    )
  end

  def deliver!
    update!(
      status: "delivered",
      delivered_at: Time.current
    )
  end

  def tracking_url
    return nil unless tracking_number.present? && carrier.present?

    case carrier.downcase
    when "usps"
      "https://tools.usps.com/go/TrackConfirmAction?tLabels=#{tracking_number}"
    when "ups"
      "https://www.ups.com/track?tracknum=#{tracking_number}"
    when "fedex"
      "https://www.fedex.com/fedextrack/?tracknumbers=#{tracking_number}"
    when "dhl"
      "https://www.dhl.com/en/express/tracking.html?AWB=#{tracking_number}"
    end
  end
end
