class ApiKey < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def self.authenticate(token)
    return nil if token.blank?

    # Handle both raw token and base64-encoded token
    decoded_token = begin
      Base64.strict_decode64(token)
    rescue ArgumentError
      token
    end

    find_by(token: decoded_token) || find_by(token: token)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
