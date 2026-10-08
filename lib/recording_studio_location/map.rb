# frozen_string_literal: true

require "recording_studio_location/map/coordinates"
require "recording_studio_location/map/preview"
require "recording_studio_location/map/adapter"
require "recording_studio_location/map/google"
require "recording_studio_location/map/open_street_map"
require "recording_studio_location/map/fake"

module RecordingStudioLocation
  # Optional map preview under search fields (and display when asked). Hosts
  # assign an adapter to +config.map+. Distinct from Geocoder: map embeds may
  # need a browser key, geocoding uses a server key, and a host can mix
  # providers.
  module Map
    class Error < StandardError; end
    class UnknownProvider < Error; end

    PROVIDER_ENV = "RECORDING_STUDIO_LOCATION_MAP_PROVIDER"
    BROWSER_API_KEY_ENV = "RECORDING_STUDIO_LOCATION_MAP_BROWSER_API_KEY"

    @providers = {
      "google" => Google,
      "open_street_map" => OpenStreetMap,
      "openstreetmap" => OpenStreetMap,
      "osm" => OpenStreetMap
    }

    class << self
      def register(name, klass)
        providers[name.to_s.strip.downcase] = klass
        klass
      end

      def providers
        @providers ||= {
          "google" => Google,
          "open_street_map" => OpenStreetMap,
          "openstreetmap" => OpenStreetMap,
          "osm" => OpenStreetMap
        }
      end

      def build(provider:, **kwargs)
        klass = adapter_class!(provider)
        return klass.new unless requires_browser_key?(klass)

        klass.new(browser_api_key: require_browser_key(kwargs[:browser_api_key]))
      end

      def from_rails_credentials(credentials = rails_credentials)
        settings = settings_from(credentials)
        provider = first_present(ENV.fetch(PROVIDER_ENV, nil), settings[:provider])
        return if provider.blank?

        build_from_credentials(provider, settings)
      end

      def enabled?(adapter = RecordingStudioLocation.configuration.map)
        adapter.respond_to?(:preview)
      end

      def preview(latitude: nil, longitude: nil, adapter: RecordingStudioLocation.configuration.map)
        return unless enabled?(adapter)

        adapter.preview(latitude: latitude, longitude: longitude)
      end

      def supported_providers
        providers.keys.sort.uniq.join(", ")
      end

      private

      def adapter_class!(provider)
        name = provider.to_s.strip.downcase
        klass = providers[name]
        return klass if klass

        raise UnknownProvider, "Unknown map provider #{provider.inspect}. Supported: #{supported_providers}"
      end

      def require_browser_key(key)
        stripped = key.to_s.strip
        raise ArgumentError, "Map browser_api_key is missing" if stripped.empty?

        stripped
      end

      def build_from_credentials(provider, settings)
        klass = providers[provider.to_s.strip.downcase]
        return unless klass
        return build(provider: provider) unless requires_browser_key?(klass)

        key = first_present(ENV.fetch(BROWSER_API_KEY_ENV, nil), settings[:browser_api_key])
        build(provider: provider, browser_api_key: key) if key
      end

      def requires_browser_key?(klass)
        klass.const_defined?(:REQUIRES_BROWSER_KEY) && klass::REQUIRES_BROWSER_KEY
      end

      def rails_credentials
        return unless defined?(Rails)
        return unless Rails.respond_to?(:application)

        application = Rails.application
        return unless application.respond_to?(:credentials)

        application.credentials
      end

      def settings_from(credentials)
        return {} if credentials.nil?

        nested = dig_map_settings(credentials)
        return {} if nested.nil?

        if nested.respond_to?(:symbolize_keys)
          nested.symbolize_keys
        elsif nested.respond_to?(:to_h)
          nested.to_h.symbolize_keys
        else
          {}
        end
      end

      def dig_map_settings(credentials)
        return unless credentials.respond_to?(:dig)

        credentials.dig(:recording_studio_location, :map) ||
          credentials.dig("recording_studio_location", "map")
      end

      def first_present(*values)
        values.map { |value| value.to_s.strip.presence }.compact.first
      end
    end
  end
end
