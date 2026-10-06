# frozen_string_literal: true

require "recording_studio/location/countries"
require "recording_studio/location/formatting"
require "recording_studio/location/geocoding"

module RecordingStudio
  # Public API for the Location addon.
  #
  # The recordable is RecordingStudio::Location::Location. Parent types are not
  # listed here. Hosts opt in with RecordingStudio::Capabilities::Location.to,
  # and Recording Studio derives the allowed parents from that capability.
  module Location
    LOCATION_TYPE = "RecordingStudio::Location::Location"

    class << self
      def configuration
        RecordingStudioLocation.configuration
      end

      # Optional adapter. Unset means geocode! and reverse! raise Missing.
      def geocoder
        configuration.geocoder
      end

      def geocoder=(adapter)
        configuration.geocoder = adapter
      end

      def country_name(code)
        Countries.name_for(code)
      end

      def country_options
        Countries.select_options
      end
    end
  end
end

RecordingStudio.register_capability(
  :location,
  source: "recording_studio_location",
  child_recordables: [RecordingStudio::Location::LOCATION_TYPE]
)
