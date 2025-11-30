# Provides duration calculation logic for heartbeats using PostgreSQL window functions
# The algorithm calculates coding time by measuring gaps between consecutive heartbeats
# and capping each gap at 2 minutes (120 seconds), as per WakaTime specification
module Heartbeatable
  extend ActiveSupport::Concern

  TIMEOUT_SECONDS = 120 # 2 minutes

  class_methods do
    # Calculate total duration in seconds for a collection of heartbeats
    # Uses PostgreSQL window functions for efficient calculation
    def calculate_duration
      return 0 if none?

      sql = <<-SQL.squish
        SELECT COALESCE(SUM(diff), 0)::integer as total
        FROM (
          SELECT CASE
            WHEN LAG(time) OVER (ORDER BY time) IS NULL THEN 0
            ELSE LEAST(
              EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (ORDER BY time)))),
              #{TIMEOUT_SECONDS}
            )
          END as diff
          FROM (#{to_sql}) AS heartbeats_sub
        ) AS diffs
      SQL

      ActiveRecord::Base.connection.select_value(sql).to_i
    end

    # Calculate duration grouped by a specific field
    def calculate_duration_by(field)
      return {} if none?

      sql = <<-SQL.squish
        SELECT #{field}, COALESCE(SUM(diff), 0)::integer as total
        FROM (
          SELECT #{field}, CASE
            WHEN LAG(time) OVER (PARTITION BY #{field} ORDER BY time) IS NULL THEN 0
            ELSE LEAST(
              EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (PARTITION BY #{field} ORDER BY time)))),
              #{TIMEOUT_SECONDS}
            )
          END as diff
          FROM (#{to_sql}) AS heartbeats_sub
        ) AS diffs
        GROUP BY #{field}
        ORDER BY total DESC
      SQL

      ActiveRecord::Base.connection.select_all(sql).rows.to_h
    end

    # Generate spans (continuous coding sessions) from heartbeats
    def to_spans
      return [] if none?

      sql = <<-SQL.squish
        WITH ordered_heartbeats AS (
          SELECT time, entity, project, language,
            LAG(time) OVER (ORDER BY time) as prev_time,
            LAG(project) OVER (ORDER BY time) as prev_project
          FROM (#{to_sql}) AS heartbeats_sub
        ),
        span_starts AS (
          SELECT time, entity, project, language, prev_time,
            CASE
              WHEN prev_time IS NULL THEN true
              WHEN EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(prev_time))) > #{TIMEOUT_SECONDS} THEN true
              WHEN project != prev_project THEN true
              ELSE false
            END as is_new_span
          FROM ordered_heartbeats
        ),
        span_groups AS (
          SELECT time, entity, project, language,
            SUM(CASE WHEN is_new_span THEN 1 ELSE 0 END) OVER (ORDER BY time) as span_id
          FROM span_starts
        )
        SELECT
          MIN(time) as start_time,
          MAX(time) as end_time,
          MAX(time) - MIN(time) as duration,
          project,
          language
        FROM span_groups
        GROUP BY span_id, project, language
        ORDER BY start_time
      SQL

      ActiveRecord::Base.connection.select_all(sql).to_a
    end
  end

  included do
    scope :in_time_range, ->(start_time, end_time) {
      where(time: start_time.to_i..end_time.to_i)
    }

    scope :on_date, ->(date, timezone = "UTC") {
      tz = TZInfo::Timezone.get(timezone)
      start_of_day = tz.local_time(date.year, date.month, date.day, 0, 0, 0)
      end_of_day = tz.local_time(date.year, date.month, date.day, 23, 59, 59)
      in_time_range(start_of_day, end_of_day)
    }

    scope :today, ->(timezone = "UTC") { on_date(Date.current, timezone) }

    scope :last_n_days, ->(days, timezone = "UTC") {
      tz = TZInfo::Timezone.get(timezone)
      now = Time.current
      start_time = (now - days.days).beginning_of_day
      in_time_range(start_time, now)
    }
  end
end
