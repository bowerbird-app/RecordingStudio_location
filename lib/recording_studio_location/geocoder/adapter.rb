# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    # Provider-agnostic place adapter. Hosts assign an instance to
    # +RecordingStudio::Location.geocoder+. Built-in Google and Fake implement
    # this surface; Mapbox/HERE/Nominatim adapters can too without UI changes.
    class Adapter
      def geocode(_query_or_location)
        raise NotImplementedError, "#{self.class}#geocode must be implemented"
      end

      def reverse(_latitude, _longitude)
        raise NotImplementedError, "#{self.class}#reverse must be implemented"
      end

      # Returns an Array of Candidate. Never raises NotFound. Blank or unknown
      # queries return [].
      def search(_query, **)
        []
      end

      # Loads structured attributes for a candidate id.
      # +depth:+ is +:full+ (venue name + address + coordinates) or +:address+.
      def details(_id, depth: LookupDepth::DEFAULT, **)
        raise NotImplementedError, "#{self.class}#details must be implemented"
      end

      def attribution
        Attribution.none
      end

      def capabilities
        {
          search: false,
          details: false,
          lookup_depths: []
        }
      end
    end
  end
end
