class AttemptProjectRepoMappingJob < ApplicationJob
  queue_as :latency_1m

  def perform(heartbeat_id)
    heartbeat = Heartbeat.find(heartbeat_id)
    user = heartbeat.user
    project_name = heartbeat.project

    return if project_name.blank?

    # Check if mapping already exists
    return if user.project_repo_mappings.exists?(project_name: project_name)

    # Try to find a matching repository
    repository = user.repositories.find_by("LOWER(name) = LOWER(?)", project_name)

    if repository
      user.project_repo_mappings.create!(
        project_name: project_name,
        repository: repository,
        auto_mapped: true
      )
      Rails.logger.info "Auto-mapped project '#{project_name}' to repository '#{repository.full_name}'"
    else
      # Create unmapped entry for manual mapping later
      user.project_repo_mappings.create!(
        project_name: project_name,
        repository: nil,
        auto_mapped: false
      )
    end
  rescue ActiveRecord::RecordNotUnique
    # Mapping already exists, ignore
  rescue ActiveRecord::RecordNotFound
    # Heartbeat was deleted, ignore
  end
end
