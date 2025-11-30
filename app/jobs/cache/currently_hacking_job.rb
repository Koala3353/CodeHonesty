module Cache
  class CurrentlyHackingJob < ApplicationJob
    queue_as :latency_1m

    def perform
      cache_key = "currently_hacking_users"

      # Users with heartbeats in the last 5 minutes
      users = User.joins(:heartbeats)
                  .where("heartbeats.time > ?", 5.minutes.ago.to_i)
                  .select("users.*, MAX(heartbeats.time) as last_active, MAX(heartbeats.project) as current_project")
                  .group("users.id")
                  .order("last_active DESC")
                  .limit(50)
                  .map do |user|
        {
          id: user.id,
          username: user.display_username,
          avatar_url: user.avatar_url,
          current_project: user.current_project,
          last_active: Time.at(user.last_active).iso8601
        }
      end

      Rails.cache.write(cache_key, users, expires_in: 1.minute)
    end
  end
end
