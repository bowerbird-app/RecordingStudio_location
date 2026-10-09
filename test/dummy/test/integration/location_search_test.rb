# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class LocationSearchTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "location-search@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)
    @adapter = RecordingStudio::Location.geocoder
  end

  test "search requires a signed-in user" do
    sign_out @user

    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :unauthorized
  end

  test "search returns candidates from the adapter without exposing secrets" do
    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :success
    payload = response.parsed_body
    assert payload["results"].any? { |result| result["id"] == "demo-mcec" }
    assert payload.key?("attribution")
    refute payload.dig("attribution", "text")
    refute_includes response.body, "api_key"
    refute_includes response.body, "test-key"
  end

  test "short queries do not hit the adapter" do
    calls_before = @adapter.search_calls.dup

    get recording_studio_location.searches_path, params: { q: "me" }, as: :json

    assert_response :success
    assert_equal [], response.parsed_body["results"]
    assert_equal calls_before, @adapter.search_calls
  end

  test "place details fill structured attributes" do
    get recording_studio_location.places_path, params: { id: "demo-mcec", lookup: "full" }, as: :json

    assert_response :success
    payload = response.parsed_body
    assert_equal "Melbourne Convention and Exhibition Centre", payload["name"]
    assert_equal "South Wharf", payload["locality"]
    assert_equal "AU", payload["country_code"]
    refute payload.key?("place_id")
  end

  test "unknown place details are not found" do
    get recording_studio_location.places_path, params: { id: "missing" }, as: :json

    assert_response :not_found
    refute_includes response.body, "api_key"
  end

  test "search helper omits the map when no map adapter is configured" do
    previous = RecordingStudioLocation.configuration.map
    RecordingStudioLocation.configuration.map = nil

    get new_location_path

    assert_response :success
    refute_includes response.body, "map-url-template-value"
    assert_select "iframe", count: 0
  ensure
    RecordingStudioLocation.configuration.map = previous
  end

  test "search helper degrades to the full form when search is unavailable" do
    previous = RecordingStudio::Location.geocoder
    RecordingStudio::Location.geocoder = nil

    get new_location_path

    assert_response :success
    refute_includes response.body, "recording-studio-location--place-search"
    assert_includes response.body, "Title"
    assert_includes response.body, "Office HQ"
    assert_includes response.body, "Optional. Your name for this place."
    assert_includes response.body, "Type"
    assert_includes response.body, "Office"
    assert_includes response.body, "Name"
    assert_includes response.body, "Melbourne Convention Centre"
    assert_includes response.body, "Address line 1"
    assert_includes response.body, "12 Smith Street"
    assert_includes response.body, "Locality"
    assert_includes response.body, "Country"
    assert_includes response.body, "Not set"
    assert_includes response.body, "Select a country"
    assert_includes response.body, "Latitude"
    assert_includes response.body, "Longitude"
    assert_includes response.body, "Optional. Leave both blank when you do not have coordinates."
    refute_includes response.body, "Search for a place"
    refute_includes response.body, ">Location</label>"
    refute_includes response.body, "Add address manually"
    refute_includes response.body, "Clear location"
    assert_select "iframe", count: 0
  ensure
    RecordingStudio::Location.geocoder = previous
  end

  test "saving a location does not call search or details" do
    search_before = @adapter.search_calls.dup
    details_before = @adapter.details_calls.dup

    post locations_path, params: {
      location: {
        name: "Typed by hand",
        locality: "Carlton",
        country_code: "AU"
      }
    }

    assert_response :redirect
    assert_equal search_before, @adapter.search_calls
    assert_equal details_before, @adapter.details_calls
  end

  test "authenticate proc is used when configured" do
    previous = RecordingStudioLocation.configuration.authenticate
    RecordingStudioLocation.configuration.authenticate = ->(controller) { controller.head :forbidden }

    get recording_studio_location.searches_path, params: { q: "melbourne" }, as: :json

    assert_response :forbidden
  ensure
    RecordingStudioLocation.configuration.authenticate = previous
  end
end
