# frozen_string_literal: true

require "test_helper"
require "json"

class GeocoderGoogleTest < Minitest::Test
  FITZROY_PAYLOAD = {
    "status" => "OK",
    "results" => [
      {
        "formatted_address" => "12 Smith Street, Fitzroy VIC 3065, Australia",
        "geometry" => { "location" => { "lat" => -37.798, "lng" => 144.978 } },
        "address_components" => [
          { "long_name" => "12", "short_name" => "12", "types" => ["street_number"] },
          { "long_name" => "Smith Street", "short_name" => "Smith St", "types" => ["route"] },
          { "long_name" => "7", "short_name" => "7", "types" => ["subpremise"] },
          { "long_name" => "Fitzroy", "short_name" => "Fitzroy", "types" => %w[locality political] },
          { "long_name" => "Victoria", "short_name" => "VIC", "types" => %w[administrative_area_level_1 political] },
          { "long_name" => "Australia", "short_name" => "AU", "types" => %w[country political] },
          { "long_name" => "3065", "short_name" => "3065", "types" => ["postal_code"] }
        ]
      }
    ]
  }.freeze

  def test_geocode_maps_google_components_without_live_network
    captured = []
    adapter = google_adapter(captured, "200", payload_json)

    result = adapter.geocode("12 Smith Street, Fitzroy")

    assert_equal 1, captured.size
    assert_includes captured.first.query, "address=12+Smith+Street%2C+Fitzroy"
    assert_includes captured.first.query, "key=test-key"
    refute_includes captured.first.query, "autocomplete"
    assert_in_delta(-37.798, result.latitude)
    assert_in_delta 144.978, result.longitude
    assert_equal "12 Smith Street", result.address_line_1
    assert_equal "7", result.address_line_2
    assert_equal "Fitzroy", result.locality
    assert_equal "VIC", result.region
    assert_equal "3065", result.postal_code
    assert_equal "AU", result.country_code
    assert_equal "12 Smith Street, Fitzroy VIC 3065, Australia", result.formatted_address
  end

  def test_reverse_sends_latlng
    captured = []
    adapter = google_adapter(captured, "200", payload_json)

    result = adapter.reverse(-37.798, 144.978)

    assert_includes captured.first.query, "latlng=-37.798%2C144.978"
    assert_equal "Fitzroy", result.locality
  end

  def test_zero_results_and_provider_errors_raise_without_leaking_the_key
    zero = google_adapter([], "200", JSON.generate({ "status" => "ZERO_RESULTS", "results" => [] }))
    denied = google_adapter([], "200", JSON.generate({ "status" => "REQUEST_DENIED", "error_message" => "nope" }))
    http_error = google_adapter([], "500", "nope")
    bad_json = google_adapter([], "200", "{not json")

    not_found = assert_raises(RecordingStudioLocation::Geocoder::NotFound) { zero.geocode("Nowhere") }
    denied_error = assert_raises(RecordingStudioLocation::Geocoder::RequestError) { denied.geocode("Melbourne") }
    http = assert_raises(RecordingStudioLocation::Geocoder::RequestError) { http_error.geocode("Melbourne") }
    json = assert_raises(RecordingStudioLocation::Geocoder::RequestError) { bad_json.geocode("Melbourne") }

    [not_found, denied_error, http, json].each do |error|
      refute_includes error.message, "test-key"
    end
    assert_includes denied_error.message, "REQUEST_DENIED"
    assert_includes http.message, "500"
  end

  def test_blank_query_and_missing_key_raise_before_http
    called = false
    http = lambda do |_uri|
      called = true
      response_double("200", JSON.generate(FITZROY_PAYLOAD))
    end

    assert_raises(RecordingStudioLocation::Geocoder::QueryError) do
      RecordingStudioLocation::Geocoder::Google.new(api_key: " ", http: http)
    end
    error = assert_raises(RecordingStudioLocation::Geocoder::QueryError) do
      RecordingStudioLocation::Geocoder::Google.new(api_key: "test-key", http: http).geocode(" ")
    end
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) do
      RecordingStudioLocation::Geocoder::Google.new(api_key: "test-key", http: http).reverse(nil, 1)
    end
    refute called
    assert_includes error.message, "address"
  end

  def test_default_http_is_not_used_when_http_is_injected
    adapter = google_adapter([], "200", payload_json)

    Net::HTTP.stub(:start, ->(*) { raise "live network is not allowed" }) do
      adapter.geocode("Fitzroy")
    end
  end

  def test_locality_falls_back_to_postal_town_and_sublocality
    payload = {
      "status" => "OK",
      "results" => [
        {
          "formatted_address" => "London",
          "geometry" => { "location" => { "lat" => 51.5, "lng" => -0.1 } },
          "address_components" => [
            { "long_name" => "London", "short_name" => "London", "types" => ["postal_town"] },
            { "long_name" => "England", "short_name" => "ENG", "types" => ["administrative_area_level_1"] },
            { "long_name" => "United Kingdom", "short_name" => "GB", "types" => ["country"] }
          ]
        }
      ]
    }
    result = google_adapter([], "200", JSON.generate(payload)).geocode("London")
    assert_equal "London", result.locality
    assert_equal "GB", result.country_code

    sublocality_payload = {
      "status" => "OK",
      "results" => [
        {
          "geometry" => { "location" => { "lat" => 1, "lng" => 2 } },
          "address_components" => [
            { "long_name" => "Shoreditch", "short_name" => "Shoreditch", "types" => ["sublocality_level_1"] }
          ]
        }
      ]
    }
    assert_equal "Shoreditch", google_adapter([], "200", JSON.generate(sublocality_payload)).reverse(1, 2).locality
  end

  def test_ok_status_with_empty_results_is_not_found
    adapter = google_adapter([], "200", JSON.generate({ "status" => "OK", "results" => [] }))

    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { adapter.geocode("Melbourne") }
  end

  def test_net_http_start_is_used_when_no_http_is_injected
    response = response_double("200", JSON.generate(FITZROY_PAYLOAD))
    adapter = RecordingStudioLocation::Geocoder::Google.new(api_key: "test-key")
    started = false

    fake_start = lambda do |host, port, *args, **options, &block|
      started = true
      assert_equal "maps.googleapis.com", host
      assert_equal 443, port
      assert_equal true, options[:use_ssl] || args.include?(:use_ssl)
      http = Object.new
      http.define_singleton_method(:request) { |_request| response }
      block.call(http)
    end

    Net::HTTP.stub(:start, fake_start) do
      result = adapter.geocode("Fitzroy")
      assert_equal "Fitzroy", result.locality
    end
    assert started
  end

  AUTOCOMPLETE_PAYLOAD = {
    "status" => "OK",
    "predictions" => [
      {
        "description" => "Melbourne Convention and Exhibition Centre, South Wharf VIC, Australia",
        "place_id" => "ChIJ-mcec",
        "structured_formatting" => { "main_text" => "Melbourne Convention and Exhibition Centre" }
      }
    ]
  }.freeze

  DETAILS_PAYLOAD = {
    "status" => "OK",
    "result" => {
      "name" => "Melbourne Convention and Exhibition Centre",
      "formatted_address" => "1 Convention Centre Place, South Wharf VIC 3006, Australia",
      "geometry" => { "location" => { "lat" => -37.8253, "lng" => 144.952 } },
      "address_components" => [
        { "long_name" => "1", "short_name" => "1", "types" => ["street_number"] },
        { "long_name" => "Convention Centre Place", "short_name" => "Convention Centre Pl", "types" => ["route"] },
        { "long_name" => "South Wharf", "short_name" => "South Wharf", "types" => %w[locality political] },
        { "long_name" => "Victoria", "short_name" => "VIC", "types" => %w[administrative_area_level_1 political] },
        { "long_name" => "Australia", "short_name" => "AU", "types" => %w[country political] },
        { "long_name" => "3006", "short_name" => "3006", "types" => ["postal_code"] }
      ]
    }
  }.freeze

  def test_search_maps_autocomplete_predictions_without_live_network
    captured = []
    adapter = google_adapter(captured, "200", JSON.generate(AUTOCOMPLETE_PAYLOAD))

    results = adapter.search("melbourne", session: "session-1")

    assert_equal 1, results.size
    assert_equal "ChIJ-mcec", results.first.id
    assert_equal "Melbourne Convention and Exhibition Centre, South Wharf VIC, Australia", results.first.label
    assert_equal "Melbourne Convention and Exhibition Centre", results.first.name
    assert_includes captured.first.path, "/maps/api/place/autocomplete/json"
    assert_includes captured.first.query, "input=melbourne"
    assert_includes captured.first.query, "sessiontoken=session-1"
    refute_includes JSON.generate(results.first.as_json), "test-key"
  end

  def test_search_returns_empty_for_zero_results_and_blank_query
    captured = []
    adapter = google_adapter(captured, "200", JSON.generate({ "status" => "ZERO_RESULTS", "predictions" => [] }))

    assert_equal [], adapter.search("nowhere")
    assert_equal [], adapter.search(" ")
    assert_equal 1, captured.size
  end

  def test_details_full_uses_place_details_and_maps_name
    captured = []
    adapter = google_adapter(captured, "200", JSON.generate(DETAILS_PAYLOAD))

    result = adapter.details("ChIJ-mcec", depth: :full, session: "session-1")

    assert_equal "Melbourne Convention and Exhibition Centre", result.name
    assert_equal "1 Convention Centre Place", result.address_line_1
    assert_equal "South Wharf", result.locality
    assert_equal "VIC", result.region
    assert_equal "3006", result.postal_code
    assert_equal "AU", result.country_code
    assert_in_delta(-37.8253, result.latitude)
    assert_includes captured.first.path, "/maps/api/place/details/json"
    assert_includes captured.first.query, "place_id=ChIJ-mcec"
    assert_includes captured.first.query, "sessiontoken=session-1"
  end

  def test_details_address_uses_geocode_by_id
    captured = []
    adapter = google_adapter(captured, "200", payload_json)

    result = adapter.details("ChIJ-fitzroy", depth: :address)

    assert_nil result.name
    assert_equal "Fitzroy", result.locality
    assert_includes captured.first.path, "/maps/api/geocode/json"
    assert_includes captured.first.query, "place_id=ChIJ-fitzroy"
  end

  def test_attribution_is_required_for_this_adapter
    adapter = google_adapter([], "200", payload_json)

    assert adapter.attribution.required?
    assert_equal "Powered by Google", adapter.attribution.text
    assert adapter.capabilities[:search]
    assert_equal %i[full address], adapter.capabilities[:lookup_depths]
  end

  def test_search_and_details_errors_do_not_leak_the_key
    denied = google_adapter([], "200", JSON.generate({ "status" => "REQUEST_DENIED" }))

    error = assert_raises(RecordingStudioLocation::Geocoder::RequestError) { denied.search("Melbourne") }
    refute_includes error.message, "test-key"
  end

  def test_transport_errors_become_request_errors
    adapter = RecordingStudioLocation::Geocoder::Google.new(api_key: "test-key")

    Net::HTTP.stub(:start, ->(*) { raise SocketError, "offline" }) do
      error = assert_raises(RecordingStudioLocation::Geocoder::RequestError) { adapter.geocode("Fitzroy") }
      assert_includes error.message, "SocketError"
      refute_includes error.message, "test-key"
    end
  end

  private

  def google_adapter(captured, code, body)
    http = lambda do |uri|
      captured << uri
      response_double(code, body)
    end

    RecordingStudioLocation::Geocoder::Google.new(api_key: "test-key", http: http)
  end

  def payload_json
    JSON.generate(FITZROY_PAYLOAD)
  end

  def response_double(code, body)
    Struct.new(:code, :body).new(code, body)
  end
end
