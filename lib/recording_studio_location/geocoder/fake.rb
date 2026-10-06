# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Fake < Adapter
      attr_reader :geocode_calls, :reverse_calls

      def initialize
        super
        @forward = {}
        @reverse = {}
        @geocode_calls = []
        @reverse_calls = []
      end

      def stub_geocode(query, result)
        @forward[Query.from(query)] = Result.wrap(result)
        self
      end

      def stub_reverse(latitude, longitude, result)
        @reverse[coordinate_key(latitude, longitude)] = Result.wrap(result)
        self
      end

      def geocode(query_or_location)
        query = Query.from(query_or_location)
        raise QueryError, "Geocoding needs an address" if query.empty?

        @geocode_calls << query
        @forward.fetch(query) { raise NotFound, "No fake geocode result for #{query.inspect}" }
      end

      def reverse(latitude, longitude)
        raise QueryError, "Reverse geocoding needs latitude and longitude" if latitude.nil? || longitude.nil?

        key = coordinate_key(latitude, longitude)
        @reverse_calls << key
        @reverse.fetch(key) { raise NotFound, "No fake reverse result for #{key}" }
      end

      private

      def coordinate_key(latitude, longitude)
        format("%<latitude>.7f,%<longitude>.7f", latitude: latitude.to_f, longitude: longitude.to_f)
      end
    end
  end
end
