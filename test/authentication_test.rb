# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"
require "devise/test/integration_helpers"
require "rails/test_help"
require_relative "dummy/test/support/accessible_grants"

class AuthenticationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include AccessibleGrants

  setup do
    @user = User.find_or_create_by!(email: "authentication-http@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @previous_authenticate = RecordingStudioLocation.configuration.authenticate
  end

  teardown do
    RecordingStudioLocation.configuration.authenticate = @previous_authenticate
  end

  test "identity callback can halt without accessible" do
    RecordingStudioLocation.configuration.authenticate = ->(controller) { controller.head :forbidden }

    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :forbidden
  end

  test "signed_in_request_is_forbidden_when_accessible_is_missing" do
    singleton = RecordingStudioLocation.singleton_class
    singleton.alias_method :accessible_available_without_test, :accessible_available?
    singleton.define_method(:accessible_available?) { false }

    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :forbidden
  ensure
    singleton = RecordingStudioLocation.singleton_class
    if singleton.method_defined?(:accessible_available_without_test)
      singleton.alias_method :accessible_available?, :accessible_available_without_test
      singleton.remove_method :accessible_available_without_test
    end
  end

  test "missing_identity_is_unauthorized" do
    RecordingStudioLocation.configuration.authenticate = nil
    sign_out @user

    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :unauthorized
  end
end
