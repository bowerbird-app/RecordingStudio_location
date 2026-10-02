# frozen_string_literal: true

require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "location is a non-root recordable whose parents come from the capability" do
    assert RecordingStudio.validate_recordable_declarations!

    declaration = RecordingStudio.recordable_declaration_for(RecordingStudio::Location::LOCATION_TYPE)

    assert_equal "Location", declaration.label
    assert_equal false, declaration.root
    refute declaration.allowed_parent_types_provided
    assert_empty RecordingStudio.declared_allowed_parent_types_for(RecordingStudio::Location::Location)
    assert_equal %w[Folder Workspace], RecordingStudio.allowed_parent_types_for(RecordingStudio::Location::Location)
    refute RecordingStudio.root_allowed?(RecordingStudio::Location::Location)
  end

  test "a location can be recorded under workspace and folder and not under page" do
    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Workspace")))
    folder_recording = record_child(Folder.new(name: unique_name("Folder")), root, root)
    page_recording = record_child(Page.new(title: unique_name("Page")), root, folder_recording)

    workspace_location = record_child(partial_location(locality: "Melbourne"), root, root)
    folder_location = record_child(partial_location(name: "Head Office"), root, folder_recording)

    assert_equal root, workspace_location.parent_recording
    assert_equal folder_recording, folder_location.parent_recording
    assert_equal workspace_location.recordable, workspace_location.recordable
    assert_equal "Melbourne, Australia", workspace_location.recordable.display_name

    error = assert_raises(RecordingStudio::InvalidParent) do
      record_child(partial_location(locality: "Sydney"), root, page_recording)
    end
    assert_equal "RecordingStudio::Location::Location cannot be recorded under Page", error.message
  end

  test "a location cannot be a root recording" do
    location = RecordingStudio::Location::Location.create!(name: "Orphan")

    assert_raises(RecordingStudio::RootNotAllowed) do
      RecordingStudio.root_recording_for(location)
    end
  end

  test "partial places are valid and several locations can share a parent" do
    root = RecordingStudio.root_recording_for(Workspace.create!(name: unique_name("Multi")))

    city = record_child(
      RecordingStudio::Location::Location.new(locality: "Melbourne", region: "Victoria", country_code: "au"),
      root,
      root
    )
    coordinates_only = record_child(
      RecordingStudio::Location::Location.new(latitude: -37.798, longitude: 144.978),
      root,
      root
    )
    named = record_child(
      RecordingStudio::Location::Location.new(name: "Fitzroy Showroom"),
      root,
      root
    )

    assert_equal "Melbourne, Victoria, Australia", city.recordable.display_name
    assert_in_delta(-37.798, coordinates_only.recordable.coordinates[0])
    assert_in_delta 144.978, coordinates_only.recordable.coordinates[1]
    assert_equal "Fitzroy Showroom", named.recordable.recordable_name
    assert_equal 3, root.child_recordings.where(recordable_type: RecordingStudio::Location::LOCATION_TYPE).count
  end

  test "blank and partial coordinates are not presented as a pair" do
    missing = RecordingStudio::Location::Location.create!(locality: "Fitzroy", country_code: "AU")
    latitude_only = RecordingStudio::Location::Location.create!(latitude: -37.8, country_code: "AU")
    both = RecordingStudio::Location::Location.create!(latitude: 0, longitude: 0)

    assert_nil missing.coordinates
    assert_nil latitude_only.coordinates
    assert_equal [0.0, 0.0], both.coordinates
    assert_equal "Fitzroy, Australia", missing.display_name
    refute_includes missing.full_address, ", ,"
  end

  test "street address formatting skips blank lines" do
    location = RecordingStudio::Location::Location.create!(
      address_line_1: "12 Smith Street",
      address_line_2: "",
      locality: "Fitzroy",
      region: "VIC",
      postal_code: "3065",
      country_code: "AU"
    )

    assert_equal "12 Smith Street, Fitzroy VIC 3065, Australia", location.full_address
    assert_equal "Fitzroy, VIC, Australia", location.display_name
  end

  test "country names and out of range coordinates are validated without a geocoder" do
    adapter = Object.new
    def adapter.method_missing(*)
      raise "geocoder should not be called"
    end
    previous = RecordingStudio::Location.geocoder
    RecordingStudio::Location.geocoder = adapter

    location = RecordingStudio::Location::Location.new(
      locality: "Melbourne",
      country_code: "Australia",
      latitude: 95,
      longitude: "north"
    )

    assert_not location.valid?
    assert_includes location.errors[:country_code], "must be a two-letter ISO country code"
    assert_includes location.errors[:latitude], "must be less than or equal to 90"
    assert_includes location.errors[:longitude], "must be a number"
    assert_same adapter, RecordingStudio::Location.geocoder
  ensure
    RecordingStudio::Location.geocoder = previous
  end

  test "an empty location is valid" do
    location = RecordingStudio::Location::Location.new

    assert_predicate location, :valid?
    assert_equal "Location", location.display_name
    assert_equal "", location.full_address
    assert_nil location.coordinates
  end

  private

  def partial_location(attributes)
    RecordingStudio::Location::Location.new({ country_code: "AU" }.merge(attributes))
  end

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
