class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # GoodJob priority queues
  QUEUES = {
    latency_10s: "latency_10s",
    latency_1m: "latency_1m",
    latency_5m: "latency_5m",
    latency_15m: "latency_15m",
    default: "default"
  }.freeze
end
