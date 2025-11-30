class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def commands
    # Handle Slack slash commands like /sailorslog
    command = params[:command]
    text = params[:text]
    user_id = params[:user_id]
    channel_id = params[:channel_id]

    user = User.find_by(slack_uid: user_id)

    unless user
      return render json: {
        response_type: "ephemeral",
        text: "Please link your Slack account first at #{root_url}"
      }
    end

    case command
    when "/sailorslog"
      handle_sailors_log(user, text, channel_id)
    else
      render json: {
        response_type: "ephemeral",
        text: "Unknown command: #{command}"
      }
    end
  end

  def events
    # Handle Slack events (like message events for bots)
    case params[:type]
    when "url_verification"
      render json: { challenge: params[:challenge] }
    when "event_callback"
      # Handle specific events
      event = params[:event]
      process_event(event)
      render json: { ok: true }
    else
      render json: { ok: true }
    end
  end

  private

  def handle_sailors_log(user, query, channel_id)
    if query.blank?
      today_duration = user.today_duration
      formatted = format_duration(today_duration)
      return render json: {
        response_type: "ephemeral",
        text: "You've coded for #{formatted} today!"
      }
    end

    # Create a sailors log entry for processing
    log = user.sailors_logs.create!(
      query: query,
      slack_channel_id: channel_id,
      status: :pending
    )

    SailorsLogPollForChangesJob.perform_later(log.id)

    render json: {
      response_type: "ephemeral",
      text: "Processing your request..."
    }
  end

  def process_event(event)
    # Handle different event types
    case event[:type]
    when "message"
      # Handle message events
    when "app_mention"
      # Handle app mentions
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
end
