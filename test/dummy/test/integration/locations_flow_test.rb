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

  test "new location form renders the search helper and nested fields" do
    get new_location_path

    assert_response :success
    assert_includes response.body, "Title"
    assert_includes response.body, "location[title]"
    assert_includes response.body, "Type"
    assert_includes response.body, "location[location_type]"
    assert_includes response.body, ">Location</label>"
    assert_includes response.body, "Search for a place or address"
    refute_includes response.body, "Enter address manually"
    refute_includes response.body, "Pick a place to fill"
    refute_includes response.body, "Edit address"
    assert_includes response.body, "Add address manually"
    assert_includes response.body, "Clear location"
    assert_includes response.body, "Done"
    assert_includes response.body, "Searching"
    assert_includes response.body, "Optional. Your name for this place."
    assert_includes response.body, "Office HQ"
    assert_includes response.body, "recording-studio-location--place-search#clear"
    assert_select "input[role='combobox'][value='']"
    assert_select "input[role='combobox'][placeholder='Search for a place or address']"
    search_field = css_select("input[role='combobox']").first.parent
    assert_includes search_field.to_html, "magnifying-glass"
    refute_includes search_field.to_html, "chevron-down"
    assert_select "[data-modal-id]", count: 0
    assert_select "[aria-label='Clear location']"
    assert_includes response.body, "Enter address"
    assert_includes response.body, "flat-pack--modal"
    assert_includes response.body, "recording-studio-location--place-search"
    assert_includes response.body, "Address line 1"
    assert_includes response.body, "Locality"
    assert_includes response.body, "Country"
    assert_includes response.body, "Latitude"
    assert_includes response.body, "Longitude"
    assert_includes response.body, "location[name]"
    assert_includes response.body, "location[country_code]"
    refute_includes response.body, "mapbox"
    refute_includes response.body, "googleapis"
    assert_includes response.body, "map-url-template-value"
    assert_select "iframe[title]"
    assert_select "iframe[src]", count: 0
    assert_select "iframe[tabindex='-1']"
    assert_select "figure.hidden"
  end

  test "creating and revising a location uses the recording and the display" do
    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      post locations_path, params: {
        location: {
          title: "Showroom HQ",
          location_type: "office",
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
    assert_includes response.body, "Showroom HQ"
    assert_includes response.body, "Fitzroy Showroom"
    assert_includes response.body, "12 Smith Street, Fitzroy VIC 3065, Australia"
    assert_includes response.body, "-37.798, 144.978"
    assert_includes response.body, "Workspace"
    assert_equal @root, recording.parent_recording
    assert_equal @root, recording.root_recording

    assert_difference -> { RecordingStudio::Location::Location.count }, 1 do
      patch location_path(recording), params: {
        location: {
          title: "Showroom HQ",
          location_type: "office",
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
    assert_equal "Showroom HQ", recording.recordable.display_name
    assert_equal "Fitzroy Showroom", recording.recordable.name
  end

  test "edit form shows a saved place summary and the manual address modal" do
    recording = @root.record(RecordingStudio::Location::Location) do |location|
      location.name = "Seeded Hall"
      location.locality = "Melbourne"
      location.country_code = "AU"
    end

    get edit_location_path(recording)

    assert_response :success
    assert_includes response.body, "Seeded Hall"
    refute_includes response.body, "Edit address"
    assert_includes response.body, "Clear location"
    assert_includes response.body, "recording-studio-location--place-search#clear"
    assert_select "[aria-label='Clear location']"
    assert_select "[data-modal-id]", count: 0
    assert_select "input[role='combobox'][value='Seeded Hall']"
    search_field = css_select("input[role='combobox']").first.parent
    assert_includes search_field.to_html, "magnifying-glass"
    refute_includes search_field.to_html, "chevron-down"
    assert_includes response.body, ">Location</label>"
    assert_includes response.body, "Enter address"
    assert_includes response.body, "Add address manually"
    refute_includes response.body, "Enter address manually"
    assert_includes response.body, "flat-pack--modal"
    assert_select "iframe[src]", count: 0
  end

  test "a saved place with coordinates renders a map on edit and display" do
    recording = @root.record(RecordingStudio::Location::Location) do |location|
      location.name = "Pinned Hall"
      location.locality = "South Wharf"
      location.country_code = "AU"
      location.latitude = -37.8253
      location.longitude = 144.952
    end

    get edit_location_path(recording)

    assert_response :success
    assert_select "iframe[src]"
    iframe_src = css_select("iframe[src]").first["src"]
    assert_includes iframe_src, "marker=-37.825300,144.952000"
    refute_includes iframe_src, "key="

    get location_path(recording)

    assert_response :success
    assert_select "iframe[src]"
    assert_includes css_select("iframe[src]").first["src"], "marker=-37.825300,144.952000"
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
