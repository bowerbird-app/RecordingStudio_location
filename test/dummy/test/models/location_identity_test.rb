# frozen_string_literal: true

require "test_helper"

class LocationIdentityTest < ActiveSupport::TestCase
  setup do
    @previous = snapshot_configuration
  end

  teardown do
    restore_configuration(@previous)
  end

  test "title location_type and icon are optional" do
    location = RecordingStudio::Location::Location.new

    assert_predicate location, :valid?
    assert_nil location.title
    assert_equal "map-pin", location.resolved_icon
  end

  test "title is limited to eighty characters" do
    location = RecordingStudio::Location::Location.new(title: "A" * 81)

    assert_not location.valid?
    assert location.errors[:title].any?
  end

  test "location_type must be a configured key" do
    location = RecordingStudio::Location::Location.new(location_type: "warehouse")

    assert_not location.valid?
    assert_includes location.errors[:location_type], "is not in the list of types"
  end

  test "a configured location_type is valid" do
    location = RecordingStudio::Location::Location.new(title: "Office HQ", location_type: "office")

    assert_predicate location, :valid?
    assert_equal "building-office", location.resolved_icon
    assert_equal "Office", location.location_type_label
  end

  test "type mode clears a submitted icon and resolves from the type" do
    RecordingStudioLocation.configuration.icon_mode = :type
    location = RecordingStudio::Location::Location.new(
      location_type: "home",
      icon: "star"
    )

    assert_predicate location, :valid?
    assert_nil location.icon
    assert_equal "home", location.resolved_icon
  end

  test "choose mode stores an allowed icon" do
    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.new(
      location_type: "office",
      icon: "star"
    )

    assert_predicate location, :valid?
    assert_equal "star", location.icon
    assert_equal "star", location.resolved_icon
  end

  test "choose mode rejects an icon outside allowed_icons" do
    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.new(icon: "sparkles")

    assert_not location.valid?
    assert_includes location.errors[:icon], "is not in the list of icons"
  end

  test "resolved_icon stays valid when the type is later removed" do
    location = RecordingStudio::Location::Location.new(location_type: "office")
    RecordingStudioLocation.configuration.location_types = {
      home: { label: "Home", icon: "home" }
    }

    assert_equal "map-pin", location.resolved_icon
  end

  test "api_payload includes identity fields and resolved icon" do
    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.new(
      title: "Office HQ",
      location_type: "office",
      icon: "briefcase",
      name: "Melbourne Convention Centre",
      locality: "Melbourne",
      country_code: "AU"
    )

    payload = location.api_payload

    assert_equal "Office HQ", payload[:title]
    assert_equal "office", payload[:location_type]
    assert_equal "briefcase", payload[:icon]
    assert_equal "briefcase", payload[:resolved_icon]
    assert_equal "Office HQ", payload[:display_name]
    assert_equal "Melbourne Convention Centre", payload[:name]
    assert_includes payload.keys, :coordinates
  end

  test "duplicate_recordable copies title type and icon" do
    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.create!(
      title: "Office HQ",
      location_type: "office",
      icon: "star",
      name: "Copied Hall"
    )

    copy = RecordingStudio.duplicate_recordable(location)

    assert_equal "Office HQ", copy.title
    assert_equal "office", copy.location_type
    assert_equal "star", copy.icon
    refute_equal location.id, copy.id
  end

  test "permitted_attributes include the identity fields" do
    assert_includes RecordingStudio::Location.permitted_attributes, :title
    assert_includes RecordingStudio::Location.permitted_attributes, :location_type
    assert_includes RecordingStudio::Location.permitted_attributes, :icon
    assert_includes RecordingStudio::Location.permitted_attributes, :name
  end

  private

  def snapshot_configuration
    configuration = RecordingStudioLocation.configuration
    {
      location_types: configuration.location_types.deep_dup,
      icon_mode: configuration.icon_mode,
      allowed_icons: configuration.allowed_icons.dup,
      default_icon: configuration.default_icon
    }
  end

  def restore_configuration(snapshot)
    configuration = RecordingStudioLocation.configuration
    configuration.location_types = snapshot.fetch(:location_types)
    configuration.icon_mode = snapshot.fetch(:icon_mode)
    configuration.allowed_icons = snapshot.fetch(:allowed_icons)
    configuration.default_icon = snapshot.fetch(:default_icon)
  end
end
