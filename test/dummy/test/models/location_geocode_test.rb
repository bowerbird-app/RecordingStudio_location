# frozen_string_literal: true

require "test_helper"

class LocationGeocodeTest < ActiveSupport::TestCase
  setup do
    @previous = RecordingStudio::Location.geocoder
    @fake = RecordingStudioLocation::Geocoder::Fake.new
    RecordingStudio::Location.geocoder = @fake
  end

  teardown do
    RecordingStudio::Location.geocoder = @previous
  end

  test "geocode! fills coordinates only and revise snapshots the change" do
    @fake.stub_geocode(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      latitude: -37.798,
      longitude: 144.978,
      address_line_1: "should not apply",
      locality: "should not apply",
      country_code: "US"
    )

    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Workspace")))
    recording = record_child(
      RecordingStudio::Location::Location.new(
        address_line_1: "12 Smith Street",
        locality: "Fitzroy",
        region: "VIC",
        postal_code: "3065",
        country_code: "AU"
      ),
      root,
      root
    )

    revised = root.revise(recording) do |location|
      location.geocode!
    end
    location = revised.recordable

    assert_in_delta(-37.798, location.latitude)
    assert_in_delta 144.978, location.longitude
    assert_equal "12 Smith Street", location.address_line_1
    assert_equal "Fitzroy", location.locality
    assert_equal "AU", location.country_code
    refute_equal recording.recordable_id, revised.recordable_id
  end

  test "reverse! fills blank address fields and keeps existing text without force" do
    @fake.stub_reverse(
      -37.798,
      144.978,
      address_line_1: "12 Smith Street",
      locality: "Fitzroy",
      region: "VIC",
      postal_code: "3065",
      country_code: "AU"
    )

    location = RecordingStudio::Location::Location.new(
      locality: "Melbourne",
      latitude: -37.798,
      longitude: 144.978
    )
    original_coordinates = location.coordinates.dup

    location.reverse!

    assert_equal original_coordinates, location.coordinates
    assert_equal "Melbourne", location.locality
    assert_equal "12 Smith Street", location.address_line_1
    assert_equal "VIC", location.region
    assert_equal "3065", location.postal_code
    assert_equal "AU", location.country_code
  end

  test "reverse! with force overwrites non-blank address fields" do
    @fake.stub_reverse(
      -37.8,
      144.9,
      locality: "Fitzroy",
      region: "VIC",
      country_code: "AU"
    )

    location = RecordingStudio::Location::Location.new(
      locality: "Melbourne",
      region: "Victoria",
      latitude: -37.8,
      longitude: 144.9
    )

    location.reverse!(force: true)

    assert_equal "Fitzroy", location.locality
    assert_equal "VIC", location.region
    assert_in_delta(-37.8, location.latitude)
    assert_in_delta 144.9, location.longitude
  end

  test "geocode! and reverse! raise when the adapter is missing or the query is blank" do
    RecordingStudio::Location.geocoder = nil
    location = RecordingStudio::Location::Location.new(locality: "Melbourne", country_code: "AU")

    error = assert_raises(RecordingStudioLocation::Geocoder::Missing) { location.geocode! }
    assert_includes error.message, "geocoder"

    RecordingStudio::Location.geocoder = @fake
    blank = RecordingStudio::Location::Location.new
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { blank.geocode! }
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { blank.reverse! }
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) do
      RecordingStudio::Location::Location.new(locality: "Unknown").geocode!
    end

    @fake.stub_geocode("Melbourne, Australia", locality: "Melbourne")
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) do
      RecordingStudio::Location::Location.new(locality: "Melbourne", country_code: "AU").geocode!
    end
  end

  test "dummy initializer leaves geocoder unset without credentials" do
    RecordingStudio::Location.geocoder = @previous

    assert_nil RecordingStudio::Location.geocoder
  end

  private

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(4)}"
  end
end
