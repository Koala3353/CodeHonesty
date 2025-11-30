require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  test "generates token on create" do
    user = users(:regular_user)
    api_key = user.api_keys.create!(name: "Test Key")
    assert api_key.token.present?
  end

  test "authenticates with valid token" do
    api_key = api_keys(:user_key)
    found = ApiKey.authenticate(api_key.token)
    assert_equal api_key, found
  end

  test "returns nil for invalid token" do
    found = ApiKey.authenticate("invalid-token")
    assert_nil found
  end

  test "belongs to user" do
    api_key = api_keys(:user_key)
    assert_equal users(:regular_user), api_key.user
  end
end
