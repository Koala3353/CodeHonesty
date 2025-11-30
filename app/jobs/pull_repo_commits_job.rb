class PullRepoCommitsJob < ApplicationJob
  queue_as :latency_5m

  def perform(repository_id)
    repository = Repository.find(repository_id)
    user = repository.user

    return if user.github_access_token_ciphertext.blank?

    github = RepoHost::GitHubService.new(user.github_access_token_ciphertext)

    # Get commits from the last 30 days
    since = 30.days.ago
    commits_data = github.commits(repository.full_name, since: since)

    commits_data.each do |commit_data|
      commit = repository.commits.find_or_initialize_by(sha: commit_data[:sha])
      commit.assign_attributes(
        user: user,
        message: commit_data[:message]&.truncate(255),
        author_name: commit_data[:author_name],
        author_email: commit_data[:author_email],
        committed_at: commit_data[:committed_at]
      )
      commit.save!
    end

    Rails.logger.info "Pulled commits for repository #{repository.full_name}: #{commits_data.size} commits"
  rescue => e
    Rails.logger.error "Failed to pull commits for repository #{repository_id}: #{e.message}"
  end
end
