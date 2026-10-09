# frozen_string_literal: true

require "recording_studio_location/geocoder/result"
require "recording_studio_location/geocoder/candidate"
require "recording_studio_location/geocoder/attribution"
require "recording_studio_location/geocoder/lookup_depth"
require "recording_studio_location/geocoder/capabilities"
require "recording_studio_location/geocoder/adapter"
require "recording_studio_location/geocoder/query"
require "recording_studio_location/geocoder/google"
require "recording_studio_location/geocoder/fake"

module RecordingStudioLocation
  # Provider-agnostic place lookup. Hosts assign an adapter to
  # +RecordingStudio::Location.geocoder+. Forward/reverse geocoding run only
  # when a location calls +geocode!+ or +reverse!+. Search helpers call
  # +#search+ and +#details+ through engine endpoints.
  module Geocoder
    class Error < StandardError; end
    class Missing < Error; end
    class QueryError < Error; end
    class NotFound < Error; end
    class RequestError < Error; end
    class UnknownProvider < Error; end

    PROVIDER_ENV = "RECORDING_STUDIO_LOCATION_GEOCODER_PROVIDER"
    API_KEY_ENV = "RECORDING_STUDIO_LOCATION_GEOCODER_API_KEY"

    @providers = { "google" => Google }

    class << self
      def register(name, klass)
        providers[name.to_s.strip.downcase] = klass
        klass
      end

      def providers
        @providers ||= { "google" => Google }
      end

      def build(provider:, **)
        name = provider.to_s.strip.downcase
        klass = providers[name]
        unless klass
          raise UnknownProvider, "Unknown geocoder provider #{provider.inspect}. Supported: #{supported_providers}"
        end

        klass.new(**)
      end

      def from_rails_credentials(credentials = rails_credentials)
        settings = settings_from(credentials)
        provider = first_present(ENV.fetch(PROVIDER_ENV, nil), settings[:provider])
        api_key = first_present(ENV.fetch(API_KEY_ENV, nil), settings[:api_key])
        return if provider.blank? || api_key.blank?

        build(provider: provider, api_key: api_key)
      end

      def supported_providers
        providers.keys.sort.join(", ")
      end

      def searchable?(adapter = RecordingStudio::Location.geocoder)
        Capabilities.searchable?(adapter)
      end

      private

      def rails_credentials
        return unless defined?(Rails)
        return unless Rails.respond_to?(:application)

        application = Rails.application
        return unless application.respond_to?(:credentials)

        application.credentials
      end

      def settings_from(credentials)
        return {} if credentials.nil?

        nested = dig_geocoder_settings(credentials)
        return {} if nested.nil?

        if nested.respond_to?(:symbolize_keys)
          nested.symbolize_keys
        elsif nested.respond_to?(:to_h)
          nested.to_h.symbolize_keys
        else
          {}
        end
      end

      def dig_geocoder_settings(credentials)
        return unless credentials.respond_to?(:dig)

        credentials.dig(:recording_studio_location, :geocoder) ||
          credentials.dig("recording_studio_location", "geocoder")
      end

      def first_present(*values)
        values.map { |value| value.to_s.strip.presence }.compact.first
      end
    end
  end
end
