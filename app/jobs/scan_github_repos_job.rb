class ScanGithubReposJob < ApplicationJob
  queue_as :latency_5m

  def perform(user_id)
    user = User.find(user_id)

    return if user.github_access_token_ciphertext.blank?

    github = RepoHost::GitHubService.new(user.github_access_token_ciphertext)

    page = 1
    loop do
      repos = github.repositories(page: page)
      break if repos.empty?

      repos.each do |repo_data|
        repository = user.repositories.find_or_initialize_by(github_id: repo_data[:github_id])
        repository.assign_attributes(repo_data)
        repository.save!
      end

      break if repos.size < 100
      page += 1
    end

    Rails.logger.info "Scanned GitHub repos for user #{user.id}: #{user.repositories.count} repositories"
  rescue => e
    Rails.logger.error "GitHub repo scan failed for user #{user_id}: #{e.message}"
  end
end
