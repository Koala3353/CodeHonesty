# Detects session anomalies like suspiciously long sessions with no breaks
class Integrity::SessionAnomalyDetector < Integrity::BaseDetector
  MAX_CONTINUOUS_HOURS = 4        # Max hours without a break
  SESSION_TIMEOUT = 120           # 2 minutes - gap between sessions
  PERFECT_DURATION_MIN_HOURS = 8  # Minimum hours for "perfect duration" flag

  def detect
    return [] if heartbeats.empty?

    detect_no_breaks
    detect_perfect_duration

    @flags
  end

  private

  def detect_no_breaks
    continuous_periods = find_continuous_periods

    continuous_periods.each do |period|
      duration_hours = period[:duration] / 3600.0

      if duration_hours > MAX_CONTINUOUS_HOURS
        add_flag(
          type: :no_breaks,
          severity: :medium,
          description: "#{duration_hours.round(1)} hours of continuous coding without a break",
          evidence: {
            duration_hours: duration_hours.round(2),
            start_time: Time.at(period[:start]).utc.iso8601,
            end_time: Time.at(period[:end]).utc.iso8601,
            heartbeat_count: period[:count]
          }
        )
      end
    end
  end

  def detect_perfect_duration
    # Group heartbeats by date
    daily_durations = calculate_daily_durations

    daily_durations.each do |date, duration|
      hours = duration / 3600.0

      # Flag if duration is exactly a round number of hours (8, 9, 10, etc.)
      if hours >= PERFECT_DURATION_MIN_HOURS && (duration % 3600 == 0)
        add_flag(
          type: :perfect_duration,
          severity: :low,
          description: "Suspiciously round session duration: exactly #{hours.to_i} hours on #{date}",
          evidence: {
            date: date.to_s,
            duration_seconds: duration,
            duration_hours: hours.to_i
          }
        )
      end
    end
  end

  def find_continuous_periods
    return [] if heartbeats.empty?

    periods = []
    sorted = heartbeats.to_a.sort_by(&:time)

    current_start = sorted.first.time
    current_end = sorted.first.time
    count = 1

    sorted.each_cons(2) do |prev, curr|
      gap = curr.time - prev.time

      if gap <= SESSION_TIMEOUT
        current_end = curr.time
        count += 1
      else
        # End current period
        periods << {
          start: current_start,
          end: current_end,
          duration: current_end - current_start,
          count: count
        }

        # Start new period
        current_start = curr.time
        current_end = curr.time
        count = 1
      end
    end

    # Add last period
    periods << {
      start: current_start,
      end: current_end,
      duration: current_end - current_start,
      count: count
    }

    periods
  end

  def calculate_daily_durations
    durations = {}

    heartbeats.group_by { |h| Time.at(h.time).utc.to_date }.each do |date, hbs|
      durations[date] = calculate_duration_for_heartbeats(hbs)
    end

    durations
  end

  def calculate_duration_for_heartbeats(hbs)
    return 0 if hbs.empty?

    sorted = hbs.sort_by(&:time)
    total = 0

    sorted.each_cons(2) do |a, b|
      gap = b.time - a.time
      total += [ gap, SESSION_TIMEOUT ].min
    end

    total
  end
end
