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

  test "new location form renders gem english when the host has no legacy override" do
    get new_location_path

    assert_response :success
    assert_includes response.body, "Title"
    assert_includes response.body, "Clear location"
    refute_includes response.body, "Place name"
    refute_includes response.body, "Wipe place"
  end

  test "host legacy locale override renders in the form" do
    I18n.backend.store_translations(
      :en,
      recording_studio_location: {
        fields: { title: "Place name" },
        search: { clear: "Wipe place" }
      }
    )

    get new_location_path

    assert_response :success
    assert_includes response.body, "Place name"
    assert_includes response.body, "Wipe place"
    assert_includes response.body, "Search for a place or address"
  ensure
    I18n.reload!
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
    refute_includes response.body, "Enter address"
    refute_includes response.body, "flat-pack--modal"
    assert_inline_address_fields(hidden: true)
    assert_place_search_reveals_fields_inline
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
    assert_flatpack_stylesheet_precedes_tailwind
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
    refute_includes response.body, "-37.798, 144.978"
    assert_select ".fp-card", count: 0
    assert_select "a[href='#{edit_location_path(recording)}']", text: "Edit location"
    refute_includes response.body, "This is recording"
    refute_includes response.body, "Sign out"
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

  test "edit form shows a saved place summary and inline address fields" do
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
    refute_includes response.body, "Enter address"
    assert_includes response.body, "Add address manually"
    refute_includes response.body, "Enter address manually"
    refute_includes response.body, "flat-pack--modal"
    assert_inline_address_fields(hidden: false)
    assert_select "iframe[src]", count: 0
  end

  test "validation errors show the inline address fields" do
    post locations_path, params: { location: { country_code: "Australia" } }

    assert_response :unprocessable_entity
    refute_includes response.body, "flat-pack--modal"
    assert_inline_address_fields(hidden: false)
    fields = address_fields_node
    assert_includes fields.to_html, "must be a two-letter ISO country code"
  end

  test "manual mode renders the full address form without search" do
    recording = @root.record(RecordingStudio::Location::Location) do |location|
      location.name = "Manual Hall"
      location.locality = "Melbourne"
      location.country_code = "AU"
    end

    get edit_location_path(recording, mode: "manual")

    assert_response :success
    assert_includes response.body, "location[title]"
    assert_includes response.body, "location[name]"
    assert_includes response.body, "Address line 1"
    assert_includes response.body, "Manual Hall"
    refute_includes response.body, "recording-studio-location--place-search"
    refute_includes response.body, "flat-pack--modal"
    refute_includes response.body, "Search for a place or address"
    refute_includes response.body, "Add address manually"
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
    assert_inline_address_fields(hidden: false)
    assert_select "iframe[src]"
    iframe_src = css_select("iframe[src]").first["src"]
    assert_includes iframe_src, "marker=-37.825300,144.952000"
    refute_includes iframe_src, "key="

    get location_path(recording)

    assert_response :success
    assert_select "iframe[src]"
    assert_includes css_select("iframe[src]").first["src"], "marker=-37.825300,144.952000"
    assert_select ".fp-card", count: 0
    assert_includes response.body, "South Wharf, Australia"
    refute_includes response.body, "-37.8253, 144.952"
    refute_includes response.body, "max-w-3xl"
    map_grid = css_select("div.grid").find { |node| node["class"].to_s.include?("md:grid-cols-2") }
    assert map_grid
    assert_equal "figure", map_grid.element_children.first.name
    assert map_grid.element_children.first.at_css("iframe")
    refute_includes map_grid.to_html, "South Wharf"
    assert_select "a[href='#{edit_location_path(recording)}']", text: "Edit location"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "This is recording"
    assert_select "h1", text: "Pinned Hall"
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

  private

  def address_fields_node
    css_select("[data-recording-studio-location--place-search-target='fields']").first
  end

  def manual_entry_node
    css_select("[data-recording-studio-location--place-search-target='manual']").first
  end

  def assert_inline_address_fields(hidden:)
    fields = address_fields_node
    manual = manual_entry_node

    assert fields
    assert manual
    if hidden
      assert_includes fields["class"].to_s.split, "hidden"
      refute_includes manual["class"].to_s.split, "hidden"
    else
      refute_includes fields["class"].to_s.split, "hidden"
      assert_includes manual["class"].to_s.split, "hidden"
    end
    assert_includes fields.to_html, "location[name]"
    assert_includes fields.to_html, "Address line 1"
    assert_includes fields.to_html, "location[country_code]"
    refute_includes fields.to_html, "location[title]"
    refute_includes fields.to_html, "location[location_type]"
    refute_includes fields.to_html, "location[icon]"
    refute_includes fields.to_html, "flat-pack--modal"
    assert_includes manual.to_html, "Add address manually"
    assert_includes manual.to_html, "recording-studio-location--place-search#openManual"
  end

  def assert_flatpack_stylesheet_precedes_tailwind
    hrefs = css_select("link[rel='stylesheet']").map { |node| node["href"].to_s }
    flatpack = hrefs.index { |href| href.include?("flat_pack/application") }
    tailwind = hrefs.index { |href| href.include?("tailwind") }

    assert flatpack, "expected flat_pack/application.css in #{hrefs.inspect}"
    assert tailwind, "expected tailwind.css in #{hrefs.inspect}"
    assert_operator flatpack, :<, tailwind
    assert_equal 1, hrefs.count { |href| href.include?("flat_pack/application") }
  end

  def assert_place_search_reveals_fields_inline
    controller = File.read(
      RecordingStudioLocation::Engine.root.join(
        "app/javascript/recording_studio_location/controllers/place_search_controller.js"
      )
    )
    template = File.read(
      RecordingStudioLocation::Engine.root.join(
        "app/views/recording_studio_location/locations/_search_fields.html.erb"
      )
    )

    refute_includes controller, "flat-pack--modal"
    assert_includes controller, 'this.fieldsTarget.classList.remove("hidden")'
    assert_includes controller, 'this.fieldsTarget.classList.add("hidden")'
    assert_includes controller, 'this.fieldsTarget.querySelector("input")?.focus()'
    refute_includes template, "FlatPack::Modal"
    assert_includes template, "recording_studio_location_fields(form, title: false, location_type: false, icon: false)"
  end
end
