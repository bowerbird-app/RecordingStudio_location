# frozen_string_literal: true

require "test_helper"

class LocationApiRegistrationTest < ActiveSupport::TestCase
  test "the default registers location endpoints on every API" do
    one = declare_api("location_every_one")
    two = declare_api("location_every_two")

    assert_equal :all, RecordingStudioLocation.configuration.register_api_endpoints_on
    with_endpoint_registration(:all) { RecordingStudioLocation::Api.register! }

    assert_location_endpoints("public")
    assert_location_endpoints(one)
    assert_location_endpoints(two)
  end

  test "a list registers location endpoints only on the named APIs" do
    staff = declare_api("location_staff")
    partners = declare_api("location_partners")
    titled = declare_api("Location Ops")

    with_endpoint_registration([:location_staff, "Location Ops"]) do
      RecordingStudioLocation::Api.register!
    end

    assert_equal "location_ops", titled
    assert_location_endpoints(staff)
    assert_location_endpoints(titled)
    refute_location_endpoints(partners)
  end

  test "false and an empty list register location endpoints on no API" do
    quiet = declare_api("location_quiet")
    empty = declare_api("location_empty")

    with_endpoint_registration(false) { RecordingStudioLocation::Api.register! }
    refute_location_endpoints(quiet)

    with_endpoint_registration([]) { RecordingStudioLocation::Api.register! }
    refute_location_endpoints(empty)
  end

  private

  def declare_api(name)
    RecordingStudioApi.configuration.api(name).name
  end

  def with_endpoint_registration(value)
    configuration = RecordingStudioLocation.configuration
    previous_choice = configuration.register_api_endpoints_on
    previous_geocoder = RecordingStudio::Location.geocoder
    RecordingStudio::Location.geocoder = RecordingStudioLocation::Geocoder::Fake.demo
    configuration.register_api_endpoints_on = value
    yield
  ensure
    configuration.register_api_endpoints_on = previous_choice
    RecordingStudio::Location.geocoder = previous_geocoder
  end

  def assert_location_endpoints(api_name)
    geocode = RecordingStudioApi.registered_endpoint(:location_geocode, api: api_name)
    reverse = RecordingStudioApi.registered_endpoint(:location_reverse, api: api_name)

    refute_nil geocode, api_name
    refute_nil reverse, api_name
    assert_equal "Look up coordinates", geocode.openapi.fetch(:summary)
    assert_equal "Fill address from coordinates", reverse.openapi.fetch(:summary)
    assert_equal ["Location"], geocode.openapi_tags
    assert_equal ["Location"], reverse.openapi_tags
    assert_includes geocode.openapi.fetch(:description), "may cost money"
    assert_includes reverse.openapi.fetch(:description), "may cost money"
    assert_equal RecordingStudioLocation::Api::Lookups::Geocode, geocode.handler
    assert_equal RecordingStudioLocation::Api::Lookups::Reverse, reverse.handler
  end

  def refute_location_endpoints(api_name)
    assert_nil RecordingStudioApi.registered_endpoint(:location_geocode, api: api_name)
    assert_nil RecordingStudioApi.registered_endpoint(:location_reverse, api: api_name)
  end
end
