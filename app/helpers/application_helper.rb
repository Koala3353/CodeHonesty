module ApplicationHelper
  def format_duration(seconds)
    return "0m" if seconds.nil? || seconds == 0

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  def cache_stats
    Thread.current[:cache_stats] ||= { hits: 0, misses: 0 }
  end
end
