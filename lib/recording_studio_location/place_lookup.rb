# frozen_string_literal: true

module RecordingStudioLocation
  class PlaceLookup
    def initialize(adapter:)
      @adapter = adapter
    end

    def result(id, depth:, session: nil)
      raise Geocoder::Missing, "Assign RecordingStudio::Location.geocoder before looking up a place" unless @adapter
      unless Geocoder::Capabilities.details?(@adapter)
        raise Geocoder::Missing, "The configured place adapter does not support details"
      end

      key = id.to_s.strip
      raise Geocoder::QueryError, "Place lookup needs an id" if key.empty?

      @adapter.details(key, depth: Geocoder::LookupDepth.normalize(depth), session: session)
    end
  end
end
