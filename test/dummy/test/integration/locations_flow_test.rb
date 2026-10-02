# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class LocationsFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "locations-flow@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    @root = RecordingStudio.root_recording_for(@workspace)
  end

  test "new location form renders the gem fields" do
    get new_location_path

    assert_response :success
    assert_includes response.body, "Address line 1"
    assert_includes response.body, "Locality"
    assert_includes response.body, "Country"
    assert_includes response.body, "Latitude"
    assert_includes response.body, "Longitude"
    assert_includes response.body, "location[name]"
    assert_includes response.body, "location[country_code]"
    refute_includes response.body, "mapbox"
    refute_includes response.body, "googleapis"
  end

  test "creating and revising a location uses the recording and the display" do
    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      post locations_path, params: {
        location: {
          name: "Fitzroy Showroom",
          address_line_1: "12 Smith Street",
          locality: "Fitzroy",
          region: "VIC",
          postal_code: "3065",
          country_code: "AU",
          latitude: "-37.798",
          longitude: "144.978"
        }
      }
    end

    recording = @root.child_recordings.order(:created_at, :id).last
    assert_redirected_to location_path(recording)
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Fitzroy Showroom"
    assert_includes response.body, "12 Smith Street, Fitzroy VIC 3065, Australia"
    assert_includes response.body, "-37.798, 144.978"
    assert_includes response.body, "Workspace"
    assert_equal @root, recording.parent_recording
    assert_equal @root, recording.root_recording

    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      patch location_path(recording), params: {
        location: {
          name: "Fitzroy Showroom",
          address_line_1: "12 Smith Street",
          locality: "Fitzroy",
          region: "Victoria",
          postal_code: "3065",
          country_code: "AU",
          latitude: "",
          longitude: ""
        }
      }
    end

    assert_redirected_to location_path(recording)
    follow_redirect!
    recording.reload

    assert_includes response.body, "12 Smith Street, Fitzroy Victoria 3065, Australia"
    refute_includes response.body, "-37.798, 144.978"
    assert_nil recording.recordable.coordinates
    assert_equal "Fitzroy Showroom", recording.recordable.display_name
  end

  test "partial location submits without coordinates or a street" do
    post locations_path, params: {
      location: {
        name: "",
        locality: "Melbourne",
        region: "Victoria",
        country_code: "AU",
        latitude: "",
        longitude: ""
      }
    }

    recording = @root.child_recordings.order(:created_at, :id).last
    assert_redirected_to location_path(recording)
    follow_redirect!

    assert_includes response.body, "Melbourne, Victoria, Australia"
    refute_includes response.body, ", ,"
    assert_nil recording.recordable.coordinates
  end
end
