# Base service class for integrity detection
class Integrity::BaseDetector
  attr_reader :user, :heartbeats, :flags

  def initialize(user, heartbeats = nil)
    @user = user
    @heartbeats = heartbeats || user.heartbeats.order(:time)
    @flags = []
  end

  def detect
    raise NotImplementedError, "Subclasses must implement #detect"
  end

  protected

  def add_flag(type:, severity:, description:, evidence: {})
    @flags << {
      type: type,
      severity: severity,
      description: description,
      evidence: evidence
    }
  end

  # Calculate time intervals between heartbeats
  def calculate_intervals
    return [] if heartbeats.count < 2

    times = heartbeats.pluck(:time).sort
    times.each_cons(2).map { |a, b| b - a }
  end

  # Calculate standard deviation
  def standard_deviation(values)
    return 0 if values.empty?

    mean = values.sum.to_f / values.size
    variance = values.map { |v| (v - mean)**2 }.sum / values.size
    Math.sqrt(variance)
  end

  # Create sliding windows over heartbeats
  def sliding_windows(size_seconds)
    return [] if heartbeats.empty?

    windows = []
    sorted = heartbeats.to_a.sort_by(&:time)
    start_idx = 0

    sorted.each_with_index do |hb, end_idx|
      # Move start forward until window is within size
      while sorted[start_idx].time < hb.time - size_seconds
        start_idx += 1
      end
      windows << sorted[start_idx..end_idx]
    end

    windows.uniq
  end
end
