# Provides timezone region groupings
module TimezoneRegions
  REGIONS = {
    "Americas" => %w[
      America/New_York America/Chicago America/Denver America/Los_Angeles
      America/Toronto America/Vancouver America/Mexico_City America/Sao_Paulo
    ],
    "Europe" => %w[
      Europe/London Europe/Paris Europe/Berlin Europe/Rome Europe/Madrid
      Europe/Amsterdam Europe/Warsaw Europe/Moscow
    ],
    "Asia" => %w[
      Asia/Tokyo Asia/Shanghai Asia/Hong_Kong Asia/Singapore Asia/Mumbai
      Asia/Seoul Asia/Dubai Asia/Bangkok
    ],
    "Pacific" => %w[
      Pacific/Auckland Pacific/Sydney Pacific/Fiji Pacific/Honolulu
    ],
    "Africa" => %w[
      Africa/Cairo Africa/Johannesburg Africa/Lagos Africa/Nairobi
    ]
  }.freeze

  def self.region_for(timezone)
    REGIONS.each do |region, timezones|
      return region if timezones.include?(timezone)
    end
    "Other"
  end

  def self.all_timezones
    ActiveSupport::TimeZone::MAPPING.values.uniq.sort
  end
end
