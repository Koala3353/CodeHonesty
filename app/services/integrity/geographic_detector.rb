# Detects geographic impossibilities - coding from different locations within short time
# Currently detects multiple IP addresses in short timeframes as a proxy for geographic distance
class Integrity::GeographicDetector < Integrity::BaseDetector
  ANALYSIS_WINDOW_SECONDS = 3600  # 1 hour window
  MIN_UNIQUE_IPS = 2              # Minimum unique IPs to flag

  def detect
    return [] if heartbeats.empty?

    detect_geographic_impossibilities

    @flags
  end

  private

  def detect_geographic_impossibilities
    # Group heartbeats by IP address
    ip_groups = heartbeats.where.not(ip_address: nil).group_by(&:ip_address)

    return if ip_groups.keys.count < MIN_UNIQUE_IPS

    # Check for multiple IPs in short time windows
    windows = sliding_windows(ANALYSIS_WINDOW_SECONDS)

    windows.each do |window|
      unique_ips = window.map(&:ip_address).compact.uniq

      if unique_ips.count >= MIN_UNIQUE_IPS
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
