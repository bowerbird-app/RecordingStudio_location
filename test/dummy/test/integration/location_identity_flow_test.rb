# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class LocationIdentityFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "location-identity@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    @root = RecordingStudio.root_recording_for(@workspace)
    @previous_mode = RecordingStudioLocation.configuration.icon_mode
  end

  teardown do
    RecordingStudioLocation.configuration.icon_mode = @previous_mode
  end

  test "type mode form shows title and type radios above search and hides the icon picker" do
    get new_location_path

    assert_response :success
    assert_includes response.body, "Title"
    assert_includes response.body, "Office HQ"
    assert_includes response.body, "location[title]"
    assert_includes response.body, "Type"
    assert_includes response.body, 'name="location[location_type]"'
    assert_includes response.body, 'type="radio"'
    assert_includes response.body, 'value="office"'
    assert_includes response.body, 'value="home"'
    assert_includes response.body, "Office"
    assert_includes response.body, "Home"
    assert_includes response.body, "flat-pack-radio-group-wrapper"
    assert_includes response.body, "sr-only"
    assert_includes response.body, 'data-flat-pack--icon-name-value="building-office"'
    assert_includes response.body, 'data-flat-pack--icon-name-value="home"'
    assert_includes response.body, ">Location</label>"
    refute_includes response.body, "recording-studio-location--identity"
    refute_includes response.body, 'name="location[icon]"'
    refute_includes response.body, "chip-group-gap"
    assert_includes response.body, "Enter address"
  end

  test "choose mode form shows icon radios from the same RadioGroup" do
    get new_location_path(icon_mode: "choose")

    assert_response :success
    assert_includes response.body, "location[title]"
    assert_includes response.body, 'name="location[location_type]"'
    assert_includes response.body, 'name="location[icon]"'
    assert_includes response.body, 'type="radio"'
    assert_includes response.body, "flat-pack-radio-group-wrapper"
    assert_includes response.body, "sr-only"
    assert_includes response.body, "recording-studio-location--identity"
    assert_includes response.body, "recording-studio-location--identity#typeChanged"
    refute_includes response.body, "recording-studio-location--identity#pick"
    refute_includes response.body, "chip-group-gap"
    refute_includes response.body, "data-icon-name"
    %w[home building-office map-pin star briefcase].each do |icon_name|
      assert_includes response.body, %(value="#{icon_name}")
    end
    assert_equal :type, RecordingStudioLocation.configuration.icon_mode
  end

  test "none mode hides the icon picker and still shows title and type" do
    get new_location_path(icon_mode: "none")

    assert_response :success
    assert_includes response.body, "location[title]"
    assert_includes response.body, 'name="location[location_type]"'
    refute_includes response.body, 'name="location[icon]"'
    refute_includes response.body, "recording-studio-location--identity#pick"
  end

  test "hosts can omit title and type fields from the search helper" do
    get new_location_path
    html = response.body

    assert_includes html, "location[title]"
    assert_includes html, "location[location_type]"

    helper_source = File.read(
      RecordingStudioLocation::Engine.root.join("app/helpers/recording_studio_location/locations_helper.rb")
    )
    assert_includes helper_source, "title: true, location_type: true, icon: true"
  end

  test "creating a location stores title and type and display shows icon plus title" do
    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      post locations_path, params: {
        location: {
          title: "Office HQ",
          location_type: "office",
          name: "Melbourne Convention Centre",
          locality: "South Wharf",
          country_code: "AU"
        }
      }
    end

    recording = @root.child_recordings.order(:created_at, :id).last
    location = recording.recordable

    assert_equal "Office HQ", location.title
    assert_equal "office", location.location_type
    assert_nil location.icon
    assert_equal "building-office", location.resolved_icon
    assert_redirected_to location_path(recording)
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Office HQ"
    assert_includes response.body, "Melbourne Convention Centre"
    assert_includes response.body, 'data-flat-pack--icon-name-value="building-office"'
  end

  test "choose mode create stores the picked icon" do
    RecordingStudioLocation.configuration.icon_mode = :choose

    post locations_path, params: {
      location: {
        title: "Home desk",
        location_type: "home",
        icon: "star",
        name: "12 Smith Street",
        locality: "Fitzroy",
        country_code: "AU"
      }
    }

    recording = @root.child_recordings.order(:created_at, :id).last
    location = recording.recordable

    assert_equal "star", location.icon
    assert_equal "star", location.resolved_icon
    follow_redirect!
    assert_includes response.body, 'data-flat-pack--icon-name-value="star"'
  ensure
    RecordingStudioLocation.configuration.icon_mode = :type
  end

  test "manual address modal omits title type and icon fields" do
    get new_location_path

    modal = css_select("[data-controller~='flat-pack--modal']").first
    assert modal
    refute_includes modal.to_html, "location[title]"
    refute_includes modal.to_html, "location[location_type]"
    refute_includes modal.to_html, "location[icon]"
    assert_includes modal.to_html, "location[name]"
    assert_includes modal.to_html, "Address line 1"
  end
end
