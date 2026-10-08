# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Google < Adapter
      GEOCODE_ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json"
      AUTOCOMPLETE_ENDPOINT = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
      DETAILS_ENDPOINT = "https://maps.googleapis.com/maps/api/place/details/json"
      DETAILS_FIELDS = "name,address_component,geometry,formatted_address,place_id"
      ATTRIBUTION_TEXT = "Powered by Google"

      def initialize(api_key:, http: nil)
        super()
        key = api_key.to_s.strip
        raise QueryError, "Geocoder api_key is missing" if key.empty?

        @client = Http.new(api_key: key, http: http)
      end

      def geocode(query_or_location)
        query = Query.from(query_or_location)
        raise QueryError, "Geocoding needs an address" if query.empty?

        geocode_lookup(address: query)
      end

      def reverse(latitude, longitude)
        raise QueryError, "Reverse geocoding needs latitude and longitude" if latitude.nil? || longitude.nil?

        geocode_lookup(latlng: "#{latitude},#{longitude}")
      end

      def search(query, session: nil, **)
        input = query.to_s.strip
        return [] if input.empty?

        params = { input: input }
        params[:sessiontoken] = session if session.present?
        payload, uri = request(AUTOCOMPLETE_ENDPOINT, params)
        return [] if @client.zero_results?(payload)

        @client.assert_ok!(payload, uri)
        AutocompleteMapper.new(payload).candidates
      end

      def details(id, depth: LookupDepth::DEFAULT, session: nil, **)
        place_id = id.to_s.strip
        raise QueryError, "Place lookup needs an id" if place_id.empty?

        case LookupDepth.normalize(depth)
        when LookupDepth::ADDRESS
          geocode_lookup(place_id: place_id)
        else
          place_details(place_id, session: session)
        end
      end

      def attribution
        Attribution.new(text: ATTRIBUTION_TEXT)
      end

      def capabilities
        {
          search: true,
          details: true,
          lookup_depths: LookupDepth::VALUES.dup
        }
      end

      private

      def geocode_lookup(params)
        payload, uri = request(GEOCODE_ENDPOINT, params)
        @client.assert_ok!(payload, uri)
        GeocodeMapper.new(payload).result
      end

      def place_details(place_id, session:)
        params = { place_id: place_id, fields: DETAILS_FIELDS }
        params[:sessiontoken] = session if session.present?
        payload, uri = request(DETAILS_ENDPOINT, params)
        @client.assert_ok!(payload, uri)
        DetailsMapper.new(payload).result
      end

      def request(endpoint, params)
        uri = @client.request_uri(endpoint, params)
        payload = @client.get(endpoint, params)
        [payload, uri]
      end
    end
  end
end

require "recording_studio_location/geocoder/google/http"
require "recording_studio_location/geocoder/google/address_components"
require "recording_studio_location/geocoder/google/mappers"
