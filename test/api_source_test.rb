# frozen_string_literal: true

require "test_helper"

class ApiSourceTest < Minitest::Test
  def test_register_has_one_api_availability_check
    source = File.read(File.expand_path("../lib/recording_studio_location/api.rb", __dir__))

    assert_equal 1, source.scan("defined?(::RecordingStudioApi)").size
    assert_includes source, "each_api"
    assert_includes source, "already registered"
    refute_includes source, "register_recordable_type_api"
    refute_includes source, "register_capability_action"
    refute_includes source, "register_resource_handler"
    refute_includes source, "const_set"
    refute_includes source, "remove_const"
    refute_includes source, "location_place_search"
    refute_includes source, "location_place_details"
  end

  def test_engine_registers_the_api_after_reload
    names = RecordingStudioLocation::Engine.initializers.map(&:name)

    assert_includes names, "recording_studio_location.api"
  end

  def test_lookup_is_not_a_core_capability
    refute RecordingStudio.registered_capabilities.key?(:location_lookup)
  end
end
