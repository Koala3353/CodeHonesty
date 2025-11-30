class SailorsLogPollForChangesJob < ApplicationJob
  queue_as :latency_10s

  def perform(sailors_log_id)
    log = SailorsLog.find(sailors_log_id)
    log.process!

    response = process_query(log.user, log.query)
    log.complete!(response)

    # Optionally post response back to Slack
    post_to_slack(log, response) if log.slack_channel_id.present?
  rescue => e
    log&.error!(e.message)
    Rails.logger.error "SailorsLog processing failed: #{e.message}"
  end

  private

  def process_query(user, query)
    case query.downcase
    when /today|now/
      duration = user.today_duration
      "You've coded for #{format_duration(duration)} today!"
    when /week|7 days/
      heartbeats = user.heartbeats.last_n_days(7, user.timezone || "UTC")
      duration = heartbeats.calculate_duration
      "You've coded for #{format_duration(duration)} in the last 7 days!"
    when /month|30 days/
      heartbeats = user.heartbeats.last_n_days(30, user.timezone || "UTC")
      duration = heartbeats.calculate_duration
      "You've coded for #{format_duration(duration)} in the last 30 days!"
    when /streak/
      streak = user.streak_count
      "Your current streak is #{streak} day#{'s' if streak != 1}!"
    when /project/
      projects = user.heartbeats.last_n_days(7, user.timezone || "UTC")
                     .calculate_duration_by(:project).first(5)
      if projects.any?
        "Your top projects this week:\n" + projects.map { |p, s| "• #{p}: #{format_duration(s)}" }.join("\n")
      else
        "No projects found in the last 7 days."
      end
    else
      "I'm not sure how to answer that. Try asking about 'today', 'this week', 'streak', or 'projects'."
    end
  end

  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours > 0
      "#{hours} hour#{'s' if hours != 1} and #{minutes} minute#{'s' if minutes != 1}"
    else
      "#{minutes} minute#{'s' if minutes != 1}"
    end
  end

  def post_to_slack(log, response)
    # TODO: Implement Slack webhook posting
    Rails.logger.info "Would post to Slack channel #{log.slack_channel_id}: #{response}"
  end
end
