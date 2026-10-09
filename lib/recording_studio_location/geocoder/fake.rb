# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Fake < Adapter
      attr_reader :geocode_calls, :reverse_calls, :search_calls, :details_calls, :attribution

      def initialize
        super
        @forward = {}
        @reverse = {}
        @search = {}
        @details = {}
        @geocode_calls = []
        @reverse_calls = []
        @search_calls = []
        @details_calls = []
        @attribution = Attribution.none
      end

      def stub_geocode(query, result)
        @forward[Query.from(query)] = Result.wrap(result)
        self
      end

      def stub_reverse(latitude, longitude, result)
        @reverse[coordinate_key(latitude, longitude)] = Result.wrap(result)
        self
      end

      def stub_search(query, candidates)
        @search[normalize_query(query)] = Array(candidates).map { |candidate| Candidate.wrap(candidate) }
        self
      end

      def stub_details(id, result)
        @details[id.to_s] = Result.wrap(result)
        self
      end

      def stub_attribution(text)
        @attribution = Attribution.new(text: text)
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

      def search(query, **)
        normalized = normalize_query(query)
        @search_calls << normalized
        return [] if normalized.empty?

        matches = []
        @search.each do |key, candidates|
          next unless key.include?(normalized) || normalized.include?(key)

          matches.concat(candidates)
        end
        matches.uniq(&:id)
      end

      def details(id, depth: LookupDepth::DEFAULT, **)
        key = id.to_s.strip
        raise QueryError, "Place lookup needs an id" if key.empty?

        @details_calls << [key, LookupDepth.normalize(depth)]
        @details.fetch(key) { raise NotFound, "No fake details result for #{key.inspect}" }
      end

      def capabilities
        {
          search: true,
          details: true,
          lookup_depths: LookupDepth::VALUES.dup
        }
      end

      def self.demo
        Demo.seed(new)
      end

      private

      def coordinate_key(latitude, longitude)
        format("%<latitude>.7f,%<longitude>.7f", latitude: latitude.to_f, longitude: longitude.to_f)
      end

      def normalize_query(query)
        query.to_s.strip.downcase
      end
    end
  end
end

require "recording_studio_location/geocoder/fake/demo"
