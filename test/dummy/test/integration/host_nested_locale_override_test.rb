# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Proves a host nested `recording_studio.location.*` override in
# config/locales wins over gem English on a real page, without touching
# I18n.load_path (Rails engines already load gem locales; hosts win by
# load order).
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
    assert_includes response.body, "HOST second address line"
    refute_includes response.body, "Address line 2"
  end
end
