# Detects fake heartbeat patterns like bot activity and regular intervals
class Integrity::HeartbeatPatternDetector < Integrity::BaseDetector
  REGULAR_INTERVAL_THRESHOLD = 0.5  # Standard deviation threshold for too-regular intervals
  IMPOSSIBLE_SPEED_LINES = 500      # Max lines per minute
  MIN_HEARTBEATS_FOR_ANALYSIS = 10  # Minimum heartbeats needed
  MIN_INTERVAL_SECONDS = 5          # Minimum reasonable interval between heartbeats
  MAX_INTERVAL_SECONDS = 300        # Maximum reasonable interval (5 minutes)
  MIN_INTERVALS_FOR_ANALYSIS = 5    # Minimum intervals needed for statistical analysis

  def detect
    return [] if heartbeats.count < MIN_HEARTBEATS_FOR_ANALYSIS

    detect_regular_intervals
    detect_impossible_typing_speed

    @flags
  end

  private

  def detect_regular_intervals
    intervals = calculate_intervals

    return if intervals.count < MIN_INTERVALS_FOR_ANALYSIS

    # Filter to reasonable intervals
    reasonable_intervals = intervals.select { |i| i >= MIN_INTERVAL_SECONDS && i <= MAX_INTERVAL_SECONDS }
    return if reasonable_intervals.count < MIN_INTERVALS_FOR_ANALYSIS

    std_dev = standard_deviation(reasonable_intervals)

    if std_dev < REGULAR_INTERVAL_THRESHOLD
      add_flag(
        type: :regular_intervals,
        severity: :high,
        description: "Heartbeat intervals are suspiciously consistent (std dev: #{std_dev.round(2)}s)",
        evidence: {
          interval_count: reasonable_intervals.count,
          std_deviation: std_dev.round(2),
          mean_interval: (reasonable_intervals.sum.to_f / reasonable_intervals.size).round(2)
        }
      )
    end
  end

  def detect_impossible_typing_speed
    # Analyze 1-minute windows
    one_minute_windows = sliding_windows(60)

    one_minute_windows.each do |window|
      lines_changed = window.select(&:is_write).sum { |h| h.lines.to_i }

      if lines_changed > IMPOSSIBLE_SPEED_LINES
        window_start = Time.at(window.first.time).utc.iso8601
        add_flag(
          type: :impossible_speed,
          severity: :critical,
          description: "#{lines_changed} lines written in 1 minute (impossible typing speed)",
          evidence: {
            lines_changed: lines_changed,
            window_start: window_start,
            heartbeat_count: window.count
          }
        )
      end
    end
  end
end
