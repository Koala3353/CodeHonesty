class SailorsLog < ApplicationRecord
  belongs_to :user

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    error: 3
  }, prefix: :status

  validates :query, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def process!
    update!(status: :processing)
  end

  def complete!(response_text)
    update!(status: :completed, response: response_text)
  end

  def error!(error_message)
    update!(status: :error, response: error_message)
  end
end
