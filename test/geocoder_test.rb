# frozen_string_literal: true

require "test_helper"

class GeocoderTest < Minitest::Test
  def setup
    @previous_provider = ENV.fetch(RecordingStudioLocation::Geocoder::PROVIDER_ENV, nil)
    @previous_api_key = ENV.fetch(RecordingStudioLocation::Geocoder::API_KEY_ENV, nil)
    ENV.delete(RecordingStudioLocation::Geocoder::PROVIDER_ENV)
    ENV.delete(RecordingStudioLocation::Geocoder::API_KEY_ENV)
  end

  def teardown
    restore_env(RecordingStudioLocation::Geocoder::PROVIDER_ENV, @previous_provider)
    restore_env(RecordingStudioLocation::Geocoder::API_KEY_ENV, @previous_api_key)
  end

  def test_build_returns_google_adapter
    adapter = RecordingStudioLocation::Geocoder.build(provider: "Google", api_key: "test-key")

    assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter
  end

  def test_build_rejects_unknown_provider
    error = assert_raises(RecordingStudioLocation::Geocoder::UnknownProvider) do
      RecordingStudioLocation::Geocoder.build(provider: "mapbox", api_key: "test-key")
    end

    assert_includes error.message, "mapbox"
    assert_includes error.message, "google"
  end

  def test_from_rails_credentials_returns_nil_when_unset
    assert_nil RecordingStudioLocation::Geocoder.from_rails_credentials(nil)
    assert_nil RecordingStudioLocation::Geocoder.from_rails_credentials({})
  end

  def test_from_rails_credentials_builds_google_from_nested_hash
    credentials = {
      recording_studio_location: {
        geocoder: {
          provider: "google",
          api_key: "from-credentials"
        }
      }
    }

    adapter = RecordingStudioLocation::Geocoder.from_rails_credentials(credentials)

    assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter
  end

  def test_from_rails_credentials_prefers_env_over_credentials
    ENV[RecordingStudioLocation::Geocoder::PROVIDER_ENV] = "google"
    ENV[RecordingStudioLocation::Geocoder::API_KEY_ENV] = "from-env"
    captured = nil

    stub_build = lambda do |**kwargs|
      captured = kwargs
      :adapter
    end

    RecordingStudioLocation::Geocoder.stub(:build, stub_build) do
      result = RecordingStudioLocation::Geocoder.from_rails_credentials(
        { recording_studio_location: { geocoder: { provider: "google", api_key: "from-credentials" } } }
      )

      assert_equal :adapter, result
    end

    assert_equal "google", captured[:provider]
    assert_equal "from-env", captured[:api_key]
  end

  def test_from_rails_credentials_can_use_env_alone
    ENV[RecordingStudioLocation::Geocoder::PROVIDER_ENV] = "google"
    ENV[RecordingStudioLocation::Geocoder::API_KEY_ENV] = "env-only"

    adapter = RecordingStudioLocation::Geocoder.from_rails_credentials(nil)

    assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter
  end

  def test_from_rails_credentials_reads_string_keys
    credentials = {
      "recording_studio_location" => {
        "geocoder" => {
          "provider" => "google",
          "api_key" => "string-keys"
        }
      }
    }

    adapter = RecordingStudioLocation::Geocoder.from_rails_credentials(credentials)

    assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter
  end

  def test_from_rails_credentials_uses_to_h_and_ignores_unreadable_settings
    to_h_credentials = Class.new do
      def dig(*keys)
        return unless keys == %i[recording_studio_location geocoder]

        Object.new.tap do |nested|
          nested.define_singleton_method(:to_h) { { provider: "google", api_key: "from-to-h" } }
        end
      end
    end.new

    adapter = RecordingStudioLocation::Geocoder.from_rails_credentials(to_h_credentials)
    assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter

    unread = Class.new do
      def dig(*)
        Object.new
      end
    end.new

    assert_nil RecordingStudioLocation::Geocoder.from_rails_credentials(unread)
  end

  def test_from_rails_credentials_reads_rails_application_credentials
    fake_app = Struct.new(:credentials).new(
      { recording_studio_location: { geocoder: { provider: "google", api_key: "from-app" } } }
    )

    Rails.stub(:application, fake_app) do
      adapter = RecordingStudioLocation::Geocoder.from_rails_credentials
      assert_instance_of RecordingStudioLocation::Geocoder::Google, adapter
    end
  end

  def test_adapter_interface_is_explicit
    adapter = RecordingStudioLocation::Geocoder::Adapter.new

    assert_raises(NotImplementedError) { adapter.geocode("Melbourne") }
    assert_raises(NotImplementedError) { adapter.reverse(-37.8, 144.9) }
  end

  def test_result_wraps_hashes_and_exposes_coordinates
    result = RecordingStudioLocation::Geocoder::Result.wrap(
      latitude: -37.798,
      longitude: 144.978,
      locality: "Fitzroy"
    )

    assert_equal([-37.798, 144.978], result.coordinates)
    assert_equal "Fitzroy", result.locality
    assert_same result, RecordingStudioLocation::Geocoder::Result.wrap(result)
    assert_nil RecordingStudioLocation::Geocoder::Result.new.coordinates
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
