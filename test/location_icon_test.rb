# frozen_string_literal: true

require "test_helper"

class LocationIconTest < Minitest::Test
  def setup
    @configuration = RecordingStudioLocation::Configuration.new
  end

  def test_resolved_icon_prefers_stored_icon
    assert_equal "star", @configuration.resolved_icon(stored_icon: "star", location_type: "office")
  end

  def test_resolved_icon_uses_type_icon_when_stored_icon_is_blank
    assert_equal "building-office", @configuration.resolved_icon(location_type: "office")
    assert_equal "home", @configuration.resolved_icon(location_type: :home)
  end

  def test_resolved_icon_falls_back_to_default_when_type_is_unknown
    assert_equal "map-pin", @configuration.resolved_icon(location_type: "warehouse")
    assert_equal "map-pin", @configuration.resolved_icon
  end

  def test_resolved_icon_keeps_stored_icon_after_it_leaves_allowed_list
    @configuration.allowed_icons = %w[home map-pin]

    assert_equal "star", @configuration.resolved_icon(stored_icon: "star", location_type: "office")
  end

  def test_resolved_icon_skips_removed_types
    @configuration.location_types = {
      home: { label: "Home", icon: "home" }
    }

    assert_equal "map-pin", @configuration.resolved_icon(location_type: "office")
  end

  def test_default_icons_exist_in_flatpack
    heroicons = File.read(
      File.expand_path("dummy/vendor/engines/flat_pack/app/javascript/flat_pack/heroicons.js", __dir__)
    )
    icons = (
      RecordingStudioLocation::Configuration::DEFAULT_ALLOWED_ICONS +
      RecordingStudioLocation::Configuration::DEFAULT_LOCATION_TYPES.values.map { |entry| entry[:icon] } +
      [RecordingStudioLocation::Configuration::DEFAULT_ICON]
    ).uniq

    icons.each do |name|
      assert_includes heroicons, %("#{name}"), "#{name} is not a FlatPack icon"
    end
  end

  def test_identity_fields_use_visual_radio_groups
    source = File.read(
      File.expand_path("../app/views/recording_studio_location/locations/_identity_fields.html.erb", __dir__)
    )

    assert_includes source, "FlatPack::RadioGroup::Component"
    assert_includes source, "variant: :inline"
    assert_includes source, "location_type_radio_options"
    assert_includes source, "allowed_icon_radio_options"
    refute_includes source, "FlatPack::Select::Component"
    refute_includes source, "FlatPack::ChipGroup::Component"
    refute_includes source, "icon_only: true"
  end

  def test_identity_controller_checks_matching_icon_radio
    source = File.read(
      File.expand_path("../app/javascript/recording_studio_location/controllers/identity_controller.js", __dir__)
    )

    assert_includes source, 'input[type="radio"][name$="[icon]"]'
    assert_includes source, "radio.checked = radio.value === icon"
    refute_includes source, "syncButtons"
    refute_includes source, "iconButton"
    refute_includes source, "data-icon-name"
  end
end

class LocationIdentityMethodsTest < Minitest::Test
  class Place
    include RecordingStudio::Location::Formatting
    include RecordingStudio::Location::Identity

    PERMITTED_ATTRIBUTES = %i[title location_type icon name].freeze

    attr_accessor :title, :location_type, :icon, :name, :address_line_1, :address_line_2,
                  :locality, :region, :postal_code, :country_code, :latitude, :longitude

    def initialize(**attributes)
      attributes.each { |name, value| public_send(:"#{name}=", value) }
    end
  end

  def setup
    @configuration = RecordingStudioLocation.configuration
    @previous_mode = @configuration.icon_mode
  end

  def teardown
    @configuration.icon_mode = @previous_mode
  end

  def test_resolved_icon_and_type_label
    place = Place.new(location_type: "office")

    assert_equal "building-office", place.resolved_icon
    assert_equal "Office", place.location_type_label
    assert_nil Place.new.location_type_label
  end

  def test_api_payload_includes_identity_fields
    @configuration.icon_mode = :choose
    place = Place.new(title: "Office HQ", location_type: "office", icon: "star", name: "Hall")

    payload = place.api_payload

    assert_equal "Office HQ", payload[:title]
    assert_equal "office", payload[:location_type]
    assert_equal "star", payload[:icon]
    assert_equal "star", payload[:resolved_icon]
    assert_equal "Office HQ", payload[:display_name]
    assert_includes payload.keys, :coordinates
  end

  def test_type_mode_clears_a_submitted_icon
    @configuration.icon_mode = :type
    place = Place.new(location_type: "home", icon: "star")
    place.send(:clear_icon_unless_choose)

    assert_nil place.icon
    assert_equal "home", place.resolved_icon
  end

  def test_choose_mode_keeps_a_submitted_icon
    @configuration.icon_mode = :choose
    place = Place.new(icon: "star")
    place.send(:clear_icon_unless_choose)

    assert_equal "star", place.icon
  end
end
