class LeaderboardDateRange
  attr_reader :period_type, :reference_date

  def initialize(period_type, reference_date = Date.current)
    @period_type = period_type.to_sym
    @reference_date = reference_date
  end

  def range
    case period_type
    when :daily
      reference_date.beginning_of_day..reference_date.end_of_day
    when :last_7_days
      (reference_date - 6.days).beginning_of_day..reference_date.end_of_day
    when :last_30_days
      (reference_date - 29.days).beginning_of_day..reference_date.end_of_day
    when :this_week
      reference_date.beginning_of_week..reference_date.end_of_week
    when :this_month
      reference_date.beginning_of_month..reference_date.end_of_month
    else
      reference_date.beginning_of_day..reference_date.end_of_day
    end
  end

  def start_timestamp
    range.begin.to_i
  end

  def end_timestamp
    range.end.to_i
  end

  def days
    (range.end.to_date - range.begin.to_date).to_i + 1
  end

  def display_name
    case period_type
    when :daily
      "#{reference_date.strftime('%B %d, %Y')}"
    when :last_7_days
      "Last 7 Days"
    when :last_30_days
      "Last 30 Days"
    when :this_week
      "This Week"
    when :this_month
      reference_date.strftime("%B %Y")
    else
      "Custom"
    end
  end
end
