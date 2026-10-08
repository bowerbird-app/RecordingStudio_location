# frozen_string_literal: true

require "test_helper"

class MapTest < Minitest::Test
  def setup
    @previous_provider = ENV.fetch(RecordingStudioLocation::Map::PROVIDER_ENV, nil)
    @previous_key = ENV.fetch(RecordingStudioLocation::Map::BROWSER_API_KEY_ENV, nil)
    ENV.delete(RecordingStudioLocation::Map::PROVIDER_ENV)
    ENV.delete(RecordingStudioLocation::Map::BROWSER_API_KEY_ENV)
  end

  def teardown
    restore_env(RecordingStudioLocation::Map::PROVIDER_ENV, @previous_provider)
    restore_env(RecordingStudioLocation::Map::BROWSER_API_KEY_ENV, @previous_key)
  end

  def test_build_returns_open_street_map_without_a_key
    adapter = RecordingStudioLocation::Map.build(provider: "OSM")

    assert_instance_of RecordingStudioLocation::Map::OpenStreetMap, adapter
  end

  def test_build_returns_google_adapter
    adapter = RecordingStudioLocation::Map.build(provider: "Google", browser_api_key: "browser-key")

    assert_instance_of RecordingStudioLocation::Map::Google, adapter
  end

  def test_build_rejects_unknown_provider
    error = assert_raises(RecordingStudioLocation::Map::UnknownProvider) do
      RecordingStudioLocation::Map.build(provider: "mapbox")
    end

    assert_includes error.message, "mapbox"
    assert_includes error.message, "google"
  end

  def test_from_rails_credentials_returns_nil_when_unset
    assert_nil RecordingStudioLocation::Map.from_rails_credentials(nil)
    assert_nil RecordingStudioLocation::Map.from_rails_credentials({})
  end

  def test_from_rails_credentials_builds_osm_without_a_key
    credentials = {
      recording_studio_location: {
        map: { provider: "open_street_map" }
      }
    }

    adapter = RecordingStudioLocation::Map.from_rails_credentials(credentials)

    assert_instance_of RecordingStudioLocation::Map::OpenStreetMap, adapter
  end

  def test_from_rails_credentials_needs_browser_key_for_google
    credentials = {
      recording_studio_location: {
        geocoder: { provider: "google", api_key: "server-key" },
        map: { provider: "google" }
      }
    }

    assert_nil RecordingStudioLocation::Map.from_rails_credentials(credentials)
  end

  def test_from_rails_credentials_builds_google_from_browser_key
    credentials = {
      recording_studio_location: {
        geocoder: { provider: "google", api_key: "server-key" },
        map: { provider: "google", browser_api_key: "browser-key" }
      }
    }

    adapter = RecordingStudioLocation::Map.from_rails_credentials(credentials)

    assert_instance_of RecordingStudioLocation::Map::Google, adapter
    url = adapter.preview(latitude: -37.8253, longitude: 144.952).url
    assert_includes url, "browser-key"
    refute_includes url, "server-key"
  end

  def test_from_rails_credentials_prefers_env_over_credentials
    ENV[RecordingStudioLocation::Map::PROVIDER_ENV] = "google"
    ENV[RecordingStudioLocation::Map::BROWSER_API_KEY_ENV] = "from-env"

    adapter = RecordingStudioLocation::Map.from_rails_credentials(
      { recording_studio_location: { map: { provider: "google", browser_api_key: "from-credentials" } } }
    )

    assert_includes adapter.preview(latitude: 0, longitude: 0).url, "from-env"
    refute_includes adapter.preview(latitude: 0, longitude: 0).url, "from-credentials"
  end

  def test_preview_is_nil_when_no_adapter_is_configured
    previous = RecordingStudioLocation.configuration.map
    RecordingStudioLocation.configuration.map = nil

    assert_nil RecordingStudioLocation::Map.preview(latitude: -37.8, longitude: 144.9)
    refute RecordingStudioLocation::Map.enabled?
  ensure
    RecordingStudioLocation.configuration.map = previous
  end

  def test_osm_preview_has_template_without_coordinates_and_url_with_them
    adapter = RecordingStudioLocation::Map::OpenStreetMap.new
    empty = adapter.preview
    filled = adapter.preview(latitude: -37.8253, longitude: 144.952)

    refute empty.visible?
    assert_includes empty.url_template, "{lat}"
    assert_includes empty.url_template, "{west}"
    refute_includes empty.url_template, "key="

    assert filled.visible?
    assert_includes filled.url, "marker=-37.825300,144.952000"
    assert_includes filled.url, "bbox="
  end

  def test_fake_preview_fills_lat_lng_placeholders
    adapter = RecordingStudioLocation::Map::Fake.new
    preview = adapter.preview(latitude: -37.8, longitude: 144.9)

    assert_equal "https://map.test/embed?lat=-37.800000&lng=144.900000", preview.url
  end

  def test_coordinates_reject_partial_and_out_of_range_values
    refute RecordingStudioLocation::Map::Coordinates.pair(nil, 144.9)
    refute RecordingStudioLocation::Map::Coordinates.pair(-37.8, "")
    refute RecordingStudioLocation::Map::Coordinates.pair(91, 0)
    refute RecordingStudioLocation::Map::Coordinates.pair(0, 181)
    assert_equal([-37.8, 144.9], RecordingStudioLocation::Map::Coordinates.pair("-37.8", "144.9"))
  end

  private

  def restore_env(name, value)
    if value.nil?
      ENV.delete(name)
    else
      ENV[name] = value
    end
  end
end
