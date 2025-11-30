class HeartbeatImportService
  attr_reader :user, :source

  BATCH_SIZE = 1000

  def initialize(user, source: :wakapi_import)
    @user = user
    @source = source
  end

  # Import heartbeats from a JSON array
  def import_from_json(heartbeats_json)
    heartbeats = JSON.parse(heartbeats_json)
    import(heartbeats)
  end

  # Import heartbeats from an array of hashes
  def import(heartbeats_array)
    imported = 0
    duplicates = 0
    errors = []

    heartbeats_array.each_slice(BATCH_SIZE) do |batch|
      batch_result = import_batch(batch)
      imported += batch_result[:imported]
      duplicates += batch_result[:duplicates]
      errors += batch_result[:errors]
    end

    {
      imported: imported,
      duplicates: duplicates,
      errors: errors,
      total: heartbeats_array.size
    }
  end

  private

  def import_batch(batch)
    imported = 0
    duplicates = 0
    errors = []

    batch.each do |hb_data|
      result = import_single(hb_data)
      case result[:status]
      when :imported
        imported += 1
      when :duplicate
        duplicates += 1
      when :error
        errors << result[:error]
      end
    end

    { imported: imported, duplicates: duplicates, errors: errors }
  end

  def import_single(data)
    heartbeat = user.heartbeats.new(
      time: parse_time(data["time"] || data[:time]),
      entity: data["entity"] || data[:entity],
      project: data["project"] || data[:project],
      language: data["language"] || data[:language],
      editor: data["editor"] || data[:editor],
      operating_system: data["operating_system"] || data[:operating_system],
      branch: data["branch"] || data[:branch],
      machine: data["machine"] || data[:machine],
      category: data["category"] || data[:category] || "coding",
      is_write: data["is_write"] || data[:is_write] || false,
      source_type: source
    )

    if heartbeat.save
      { status: :imported }
    elsif heartbeat.errors[:fields_hash].any?
      { status: :duplicate }
    else
      { status: :error, error: heartbeat.errors.full_messages.join(", ") }
    end
  end

  def parse_time(time_value)
    case time_value
    when Integer, Float
      time_value.to_i
    when String
      if time_value.match?(/^\d+$/)
        time_value.to_i
      else
        Time.parse(time_value).to_i
      end
    else
      Time.current.to_i
    end
  end
end
