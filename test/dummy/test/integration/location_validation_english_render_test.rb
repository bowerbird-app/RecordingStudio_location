# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Render-level assert: invalid create keeps main's English validation copy on
# the real new-location form (byte-identical wording).
class LocationValidationEnglishRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_load_path = I18n.load_path.dup
    @previous_icon_mode = RecordingStudioLocation.configuration.icon_mode
    @user = User.find_or_create_by!(email: "validation-english-render@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)
  end

  teardown do
    RecordingStudioLocation.configuration.icon_mode = @previous_icon_mode
    assert_equal @previous_load_path, I18n.load_path,
                 "tests must not leave I18n.load_path modified"
  end

  test "invalid create renders main english validation messages" do
    RecordingStudioLocation.configuration.icon_mode = :choose

    post locations_path, params: {
      location: {
        location_type: "warehouse",
        icon: "sparkles",
        country_code: "Australia"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "is not in the list of types"
    assert_includes response.body, "is not in the list of icons"
    assert_includes response.body, "must be a two-letter ISO country code"
    refute_includes response.body, "HOST is not in the list of types"
    refute_includes response.body, "translation missing"
  end
end
