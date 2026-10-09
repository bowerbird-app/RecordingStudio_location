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

  def test_search_matches_stub_keys_and_never_raises_not_found
    @fake.stub_search(
      "mel",
      [{ id: "demo-mcec", label: "Melbourne Convention Centre", name: "Melbourne Convention Centre" }]
    )

    results = @fake.search("Melbourne")

    assert_equal 1, results.size
    assert_equal "demo-mcec", results.first.id
    assert_equal ["melbourne"], @fake.search_calls
    assert_equal [], @fake.search("unknown place")
    assert_equal [], @fake.search(" ")
  end

  def test_details_uses_stubs_and_records_depth
    @fake.stub_details("demo-mcec", name: "Melbourne Convention Centre", locality: "South Wharf")

    result = @fake.details("demo-mcec", depth: :address)

    assert_equal "Melbourne Convention Centre", result.name
    assert_equal "South Wharf", result.locality
    assert_equal [["demo-mcec", :address]], @fake.details_calls
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { @fake.details("missing") }
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { @fake.details(" ") }
  end

  def test_demo_adapter_has_searchable_melbourne_results
    demo = RecordingStudioLocation::Geocoder::Fake.demo

    results = demo.search("melbourne")
    details = demo.details("demo-mcec")

    assert demo.capabilities[:search]
    refute demo.attribution.required?
    assert(results.any? { |candidate| candidate.id == "demo-mcec" })
    assert_equal "Melbourne Convention and Exhibition Centre", details.name
    assert_equal "AU", details.country_code
  end

  def test_missing_stubs_and_blank_queries_raise
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { @fake.geocode(" ") }
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { @fake.reverse(nil, 144.9) }
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { @fake.geocode("Unknown") }
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { @fake.reverse(0, 0) }
  end
end
