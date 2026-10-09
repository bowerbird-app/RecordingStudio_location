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
    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioLocation.configure

    assert_kind_of RecordingStudioLocation::Configuration, RecordingStudioLocation.configuration
  end
end
