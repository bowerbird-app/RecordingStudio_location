# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Proves a host nested `recording_studio.location.*` override in
# config/locales wins over gem English on a real page. Uses
# map.title_with_coordinates (Stimulus data attribute only) so the dummy
# UI and other rendered tests keep default English for common labels.
# Does not touch I18n.load_path.
class HostNestedLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @original_load_path = I18n.load_path.dup
    @user = User.find_or_create_by!(email: "host-locale-override@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)
  end

  teardown do
    assert_equal @original_load_path, I18n.load_path,
                 "tests must not leave I18n.load_path modified"
  end

  test "host nested locale override wins on the new location page" do
    host_locale = Rails.root.join("config/locales/recording_studio_location_host.en.yml")
    assert File.exist?(host_locale), "expected host override file at #{host_locale}"

    get new_location_path

    assert_response :success
    assert_includes response.body, "HOST map %{latitude}, %{longitude}"
    refute_includes response.body, "Map of %{latitude}, %{longitude}"
  end
end
