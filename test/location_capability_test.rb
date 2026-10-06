# frozen_string_literal: true

require "test_helper"

class LocationCapabilityTest < Minitest::Test
  module Probe
    HostType = Class.new
    OtherType = Class.new
  end

  def setup
    @original_capabilities =
      RecordingStudio.configuration.instance_variable_get(:@capabilities).transform_values(&:dup)
    @original_capability_options =
      RecordingStudio.configuration.instance_variable_get(:@capability_options).dup
    RecordingStudio.configuration.instance_variable_set(:@capabilities, {})
    RecordingStudio.configuration.instance_variable_set(:@capability_options, {})
  end

  def teardown
    RecordingStudio.configuration.instance_variable_set(:@capabilities, @original_capabilities)
    RecordingStudio.configuration.instance_variable_set(:@capability_options, @original_capability_options)
  end

  def test_to_wraps_include_for_and_does_not_register_the_capability
    source = File.read(File.expand_path("../lib/recording_studio/capabilities/location.rb", __dir__))

    assert_includes source, "def self.to(**)"
    assert_includes source, "RecordingStudio::Capabilities.include_for(:location, **)"
    refute_includes source, "enable_capability"
    refute_includes source, "register_capability"
    refute_includes source, "allowed_parent_types"
  end

  def test_to_delegates_to_include_for
    captured_name = nil
    captured_options = nil
    factory = Module.new

    RecordingStudio::Capabilities.stub :include_for, lambda { |name, **options|
      captured_name = name
      captured_options = options
      factory
    } do
      result = RecordingStudio::Capabilities::Location.to

      assert_same factory, result
    end

    assert_equal :location, captured_name
    assert_equal({}, captured_options)
  end

  def test_including_to_enables_location_only_on_that_type
    Probe::HostType.include(RecordingStudio::Capabilities::Location.to)

    assert RecordingStudio.capability_enabled?(:location, for: Probe::HostType)
    refute RecordingStudio.capability_enabled?(:location, for: Probe::OtherType)
  end

  def test_registration_owns_the_location_recordable_without_enabling_a_parent
    registration = RecordingStudio.registered_capabilities.fetch(:location)

    assert_equal "recording_studio_location", registration[:source]
    assert_equal ["RecordingStudio::Location::Location"], registration.fetch(:child_recordables)
    assert_empty RecordingStudio.configuration.enabled_recordable_types_for(:location)
  end
end
