Rails.application.config.good_job = {
  execution_mode: :async,
  queues: "latency_10s:2;latency_1m:2;latency_5m:1;latency_15m:1;default:2",
  max_threads: 5,
  poll_interval: 5,
  shutdown_timeout: 25,
  enable_cron: true,
  cron: {
    # Update daily leaderboard every 15 minutes
    daily_leaderboard: {
      cron: "*/15 * * * *",
      class: "LeaderboardUpdateJob",
      args: [:daily]
    },
    # Update weekly leaderboard every 30 minutes
    weekly_leaderboard: {
      cron: "*/30 * * * *",
      class: "LeaderboardUpdateJob",
      args: [:last_7_days]
    },
    # Cache warming jobs
    heartbeat_counts: {
      cron: "*/15 * * * *",
      class: "Cache::HeartbeatCountsJob"
    },
    active_users_graph: {
      cron: "*/15 * * * *",
      class: "Cache::ActiveUsersGraphDataJob"
    },
    currently_hacking: {
      cron: "* * * * *",
      class: "Cache::CurrentlyHackingJob"
    },
    home_stats: {
      cron: "*/15 * * * *",
      class: "Cache::HomeStatsJob"
    }
  }
}
