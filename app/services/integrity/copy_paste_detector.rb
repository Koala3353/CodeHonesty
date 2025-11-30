# Detects copy-paste patterns by analyzing code velocity vs heartbeat activity
class Integrity::CopyPasteDetector < Integrity::BaseDetector
  AVG_CHARS_PER_MINUTE = 300      # Average typing speed in characters
  AVG_CHARS_PER_LINE = 80         # Average characters per line of code
  MIN_CHARS_FOR_FLAG = 500        # Minimum characters to consider
  VELOCITY_THRESHOLD = 0.2        # If actual time < expected time * threshold
  SESSION_GAP_SECONDS = 300       # Gap indicating different session (5 minutes)

  def detect
    return [] if heartbeats.empty?

    detect_copy_paste_patterns

    @flags
  end

  private

  def detect_copy_paste_patterns
    # Get heartbeats with line changes
    write_heartbeats = heartbeats.where(is_write: true).where("lines > 0").order(:time)

    return if write_heartbeats.count < 2

    # Analyze changes between consecutive writes
    write_heartbeats.each_cons(2) do |prev, curr|
      analyze_code_change(prev, curr)
    end
  end

  def analyze_code_change(prev_hb, curr_hb)
    lines_added = curr_hb.lines.to_i
    time_diff = curr_hb.time - prev_hb.time

    # Skip if time difference is too large (different session)
    return if time_diff > SESSION_GAP_SECONDS

    # Estimate characters based on average chars per line
    estimated_chars = lines_added * AVG_CHARS_PER_LINE

    return if estimated_chars < MIN_CHARS_FOR_FLAG

    # Expected typing time in seconds
    expected_time = (estimated_chars.to_f / AVG_CHARS_PER_MINUTE) * 60

    # If actual time is much less than expected
    if time_diff < expected_time * VELOCITY_THRESHOLD
      add_flag(
        type: :copy_paste,
        severity: :high,
        description: "Large code addition (#{lines_added} lines) with insufficient typing time",
        evidence: {
          lines_added: lines_added,
          estimated_chars: estimated_chars,
          actual_time_seconds: time_diff.to_i,
          expected_time_seconds: expected_time.to_i,
          file: curr_hb.entity,
          timestamp: Time.at(curr_hb.time).utc.iso8601
        }
      )
    end
  end
end
