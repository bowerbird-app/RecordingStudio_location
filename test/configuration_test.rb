# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioLocation::Configuration.new
  end

  def test_merge_updates_geocoder
    adapter = Object.new
    @configuration.merge!(geocoder: adapter)

    assert_same adapter, @configuration.geocoder
  end

  def test_merge_updates_map
    adapter = Object.new
    @configuration.merge!(map: adapter)

    assert_same adapter, @configuration.map
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", geocoder: "kept")

    refute_respond_to @configuration, :unknown_key
    assert_equal "kept", @configuration.geocoder
  end

  def test_merge_with_non_enumerable_is_noop
    @configuration.geocoder = "existing"

    @configuration.merge!(nil)

    assert_equal "existing", @configuration.geocoder
  end

  def test_initialize_defaults_geocoder_to_nil_and_uses_core_hooks
    configuration = RecordingStudioLocation::Configuration.new

    assert_nil configuration.geocoder
    assert_nil configuration.map
    assert_nil configuration.authenticate
    assert_equal :full, configuration.lookup_depth
    assert_equal :type, configuration.icon_mode
    assert_equal %w[home building-office map-pin star briefcase], configuration.allowed_icons
    assert_equal "map-pin", configuration.default_icon
    assert_equal %w[office home venue other], configuration.location_type_keys
    assert_equal "building-office", configuration.icon_for_type(:office)
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("geocoder" => "string-key")

    assert_equal "string-key", @configuration.geocoder
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_nil result.fetch(:geocoder)
    assert_nil result.fetch(:map)
    assert_nil result.fetch(:authenticate)
    assert_equal :full, result.fetch(:lookup_depth)
    assert_equal :type, result.fetch(:icon_mode)
    assert_equal "map-pin", result.fetch(:default_icon)
    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioLocation.configure

    assert_kind_of RecordingStudioLocation::Configuration, RecordingStudioLocation.configuration
  end

  def test_location_types_can_be_overridden
    @configuration.location_types = {
      "studio" => { "label" => "Studio", "icon" => "briefcase" }
    }

    assert_equal %w[studio], @configuration.location_type_keys
    assert_equal "briefcase", @configuration.icon_for_type("studio")
    assert_equal "Studio", @configuration.location_type_label(:studio)
  end

  def test_icon_mode_normalizes_unknown_values_to_type
    @configuration.icon_mode = "choose"
    assert_predicate @configuration, :icon_mode_choose?

    @configuration.icon_mode = "none"
    assert_predicate @configuration, :icon_mode_none?

    @configuration.icon_mode = "nope"
    assert_predicate @configuration, :icon_mode_type?
  end

  def test_merge_updates_identity_settings
    @configuration.merge!(
      icon_mode: "choose",
      allowed_icons: %w[home star],
      default_icon: "star",
      location_types: { home: { label: "House", icon: "home" } }
    )

    assert_equal :choose, @configuration.icon_mode
    assert_equal %w[home star], @configuration.allowed_icons
    assert_equal "star", @configuration.default_icon
    assert_equal "House", @configuration.location_type_label(:home)
  end

  def test_radio_options_include_icons
    type_options = @configuration.location_type_radio_options
    office = type_options.find { |option| option[:value] == "office" }

    assert office
    assert_equal "Office", office.fetch(:label)
    assert_equal "building-office", office.fetch(:icon)

    icon_options = @configuration.allowed_icon_radio_options
    home = icon_options.find { |option| option[:value] == "home" }

    assert home
    assert_equal "home", home.fetch(:icon)
    assert home.fetch(:label).present?

    map = @configuration.type_icon_map
    assert_equal "building-office", map.fetch("office")
    assert_equal "home", map.fetch("home")
  end

  def test_blank_default_icon_falls_back
    @configuration.default_icon = "   "
    assert_equal "map-pin", @configuration.default_icon

    @configuration.allowed_icons = [" home ", "", nil, "star"]
    assert_equal %w[home star], @configuration.allowed_icons
  end
end
