module RepoHost
  class GitHubService
    BASE_URL = "https://api.github.com"

    attr_reader :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    # Fetch user's repositories
    def repositories(page: 1, per_page: 100)
      response = get("/user/repos", {
        page: page,
        per_page: per_page,
        sort: "pushed",
        direction: "desc"
      })

      response.map do |repo|
        {
          github_id: repo["id"].to_s,
          name: repo["name"],
          full_name: repo["full_name"],
          url: repo["html_url"],
          default_branch: repo["default_branch"],
          private: repo["private"],
          language: repo["language"],
          description: repo["description"],
          pushed_at: repo["pushed_at"]
        }
      end
    end

    # Fetch commits for a repository
    def commits(full_name, since: nil, until_date: nil, page: 1, per_page: 100)
      params = { page: page, per_page: per_page }
      params[:since] = since.iso8601 if since
      params[:until] = until_date.iso8601 if until_date

      response = get("/repos/#{full_name}/commits", params)

      response.map do |commit|
        {
          sha: commit["sha"],
          message: commit.dig("commit", "message"),
          author_name: commit.dig("commit", "author", "name"),
          author_email: commit.dig("commit", "author", "email"),
          committed_at: commit.dig("commit", "author", "date")
        }
      end
    rescue => e
      Rails.logger.error "Failed to fetch commits for #{full_name}: #{e.message}"
      []
    end

    # Get user info
    def user_info
      get("/user")
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Accept"] = "application/vnd.github.v3+json"
      request["User-Agent"] = "Hackatime"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPUnauthorized
        raise "GitHub API: Unauthorized"
      when Net::HTTPNotFound
        raise "GitHub API: Not Found"
      else
        raise "GitHub API Error: #{response.code} - #{response.body}"
      end
    end
  end
end
