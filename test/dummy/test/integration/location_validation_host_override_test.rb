# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Appends the test-only host override fixture LAST on I18n.load_path, posts an
# invalid location, and asserts the host English wins on a real page. Restores
# load_path and the I18n backend afterward.
class LocationValidationHostOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_backend = I18n.backend
    @previous_load_path = I18n.load_path.dup
    @previous_locale = I18n.locale
    @previous_icon_mode = RecordingStudioLocation.configuration.icon_mode

    @user = User.find_or_create_by!(email: "validation-host-override@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)
  end

  teardown do
    RecordingStudioLocation.configuration.icon_mode = @previous_icon_mode
    I18n.load_path = @previous_load_path
    I18n.backend = @previous_backend
    I18n.locale = @previous_locale
    assert_equal @previous_load_path, I18n.load_path,
                 "tests must not leave I18n.load_path modified"
  end

  test "host validation override wins on the new location form" do
    host = Rails.root.join("test/locales/location_host_override.en.yml")
    assert File.exist?(host), "expected test-only host override at #{host}"

    I18n.load_path = @previous_load_path + [host.to_s]
    I18n.reload!
    I18n.locale = :en

    RecordingStudioLocation.configuration.icon_mode = :choose

    post locations_path, params: {
      location: {
        location_type: "warehouse",
        icon: "sparkles",
        country_code: "Australia"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "HOST is not in the list of types"
    assert_includes response.body, "HOST is not in the list of icons"
    assert_includes response.body, "HOST must be a two-letter ISO country code"
    refute_includes response.body, "translation missing"
  end
end
