# Provides time range filtering for models
module TimeRangeFilterable
  extend ActiveSupport::Concern

  class_methods do
    def in_date_range(start_date, end_date, date_column: :created_at)
      where(date_column => start_date.beginning_of_day..end_date.end_of_day)
    end

    def today(date_column: :created_at)
      where(date_column => Date.current.all_day)
    end

    def yesterday(date_column: :created_at)
      where(date_column => Date.yesterday.all_day)
    end

    def this_week(date_column: :created_at)
      where(date_column => Date.current.beginning_of_week..Date.current.end_of_week)
    end

    def this_month(date_column: :created_at)
      where(date_column => Date.current.beginning_of_month..Date.current.end_of_month)
    end

    def last_n_days(days, date_column: :created_at)
      where(date_column => days.days.ago.beginning_of_day..Time.current)
    end
  end
end
