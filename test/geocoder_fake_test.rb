# frozen_string_literal: true

require "test_helper"

class GeocoderFakeTest < Minitest::Test
  def setup
    @fake = RecordingStudioLocation::Geocoder::Fake.new
  end

  def test_geocode_and_reverse_use_stubs_and_record_calls
    @fake.stub_geocode("Fitzroy, VIC, Australia", latitude: -37.798, longitude: 144.978, locality: "ignored")
    @fake.stub_reverse(-37.798, 144.978, locality: "Fitzroy", region: "VIC")

    forward = @fake.geocode("Fitzroy, VIC, Australia")
    reverse = @fake.reverse(-37.798, 144.978)

    assert_in_delta(-37.798, forward.latitude)
    assert_in_delta 144.978, forward.longitude
    assert_equal "Fitzroy", reverse.locality
    assert_equal ["Fitzroy, VIC, Australia"], @fake.geocode_calls
    assert_equal ["-37.7980000,144.9780000"], @fake.reverse_calls
  end

  def test_missing_stubs_and_blank_queries_raise
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { @fake.geocode(" ") }
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { @fake.reverse(nil, 144.9) }
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { @fake.geocode("Unknown") }
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { @fake.reverse(0, 0) }
  end
end
