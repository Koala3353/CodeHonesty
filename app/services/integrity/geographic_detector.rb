# Detects geographic impossibilities - coding from distant locations within short time
class Integrity::GeographicDetector < Integrity::BaseDetector
  MAX_DISTANCE_KM = 500           # Max reasonable distance in 1 hour
  ANALYSIS_WINDOW_SECONDS = 3600  # 1 hour window

  def detect
    return [] if heartbeats.empty?

    detect_geographic_impossibilities

    @flags
  end

  private

  def detect_geographic_impossibilities
    # Group heartbeats by IP address
    ip_groups = heartbeats.where.not(ip_address: nil).group_by(&:ip_address)

    return if ip_groups.keys.count < 2

    # Check for multiple IPs in short time windows
    windows = sliding_windows(ANALYSIS_WINDOW_SECONDS)

    windows.each do |window|
      unique_ips = window.map(&:ip_address).compact.uniq

      if unique_ips.count > 1
        # Flag multiple IPs in same window (without actual geolocation)
        add_flag(
          type: :geographic_impossibility,
          severity: :high,
          description: "Activity from #{unique_ips.count} different IP addresses within 1 hour",
          evidence: {
            ip_count: unique_ips.count,
            ip_addresses: unique_ips.map(&:to_s),
            window_start: Time.at(window.first.time).utc.iso8601,
            window_end: Time.at(window.last.time).utc.iso8601
          }
        )
      end
    end
  end
end
