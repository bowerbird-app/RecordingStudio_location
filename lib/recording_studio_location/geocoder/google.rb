# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"

module RecordingStudioLocation
  module Geocoder
    class Google < Adapter
      ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json"
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10

      def initialize(api_key:, http: nil)
        super()
        key = api_key.to_s.strip
        raise QueryError, "Geocoder api_key is missing" if key.empty?

        @api_key = key
        @http = http
      end

      def geocode(query_or_location)
        query = Query.from(query_or_location)
        raise QueryError, "Geocoding needs an address" if query.empty?

        lookup(address: query)
      end

      def reverse(latitude, longitude)
        raise QueryError, "Reverse geocoding needs latitude and longitude" if latitude.nil? || longitude.nil?

        lookup(latlng: "#{latitude},#{longitude}")
      end

      private

      def lookup(params)
        uri = request_uri(params)
        response = perform_request(uri)
        payload = parse_json(response, uri)
        assert_ok!(payload, uri)
        ResultMapper.new(payload).result
      end

      def request_uri(params)
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(params.merge(key: @api_key))
        uri
      end

      def perform_request(uri)
        return @http.call(uri) if @http

        start_ssl_get(uri)
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, OpenSSL::SSL::SSLError => e
        raise RequestError, "Geocoding request failed (#{e.class})"
      end

      def start_ssl_get(uri)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          open_timeout: OPEN_TIMEOUT,
          read_timeout: READ_TIMEOUT
        ) do |http|
          http.request(Net::HTTP::Get.new(uri.request_uri))
        end
      end

      def parse_json(response, uri)
        unless response.respond_to?(:code) && response.code.to_s.start_with?("2")
          raise RequestError, "Geocoding HTTP #{response_code(response)} for #{safe_uri(uri)}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError
        raise RequestError, "Geocoding returned invalid JSON for #{safe_uri(uri)}"
      end

      def assert_ok!(payload, uri)
        status = payload["status"].to_s
        return if status == "OK"

        raise NotFound, "No geocoding result for #{safe_uri(uri)}" if status == "ZERO_RESULTS"

        raise RequestError, "Geocoding #{status} for #{safe_uri(uri)}"
      end

      def response_code(response)
        response.respond_to?(:code) ? response.code : "unknown"
      end

      def safe_uri(uri)
        filtered = uri.dup
        params = URI.decode_www_form(filtered.query.to_s).to_h.except("key")
        filtered.query = URI.encode_www_form(params)
        filtered.to_s
      end

      class ResultMapper
        def initialize(payload)
          @payload = payload
          @place = Array(payload["results"]).first
        end

        def result
          raise NotFound, "Geocoding returned no results" if @place.nil?

          Result.new(**mapped_attributes)
        end

        private

        def mapped_attributes
          geometry.merge(AddressComponents.new(@place["address_components"]).to_h).merge(
            formatted_address: @place["formatted_address"],
            raw: @payload
          )
        end

        def geometry
          location = @place.dig("geometry", "location") || {}
          { latitude: location["lat"], longitude: location["lng"] }
        end
      end

      class AddressComponents
        def initialize(components)
          @by_type = {}
          Array(components).each do |component|
            Array(component["types"]).each do |type|
              @by_type[type] ||= component
            end
          end
        end

        def street_line
          [long_name("street_number"), long_name("route")].compact.join(" ").presence
        end

        def unit
          long_name("subpremise") || long_name("premise")
        end

        def locality
          long_name("locality") ||
            long_name("postal_town") ||
            long_name("sublocality") ||
            long_name("sublocality_level_1")
        end

        def region
          short_name("administrative_area_level_1") || long_name("administrative_area_level_1")
        end

        def postal_code
          long_name("postal_code")
        end

        def country_code
          short_name("country")&.upcase
        end

        def to_h
          {
            address_line_1: street_line,
            address_line_2: unit,
            locality: locality,
            region: region,
            postal_code: postal_code,
            country_code: country_code
          }
        end

        private

        def long_name(type)
          text(@by_type.dig(type, "long_name"))
        end

        def short_name(type)
          text(@by_type.dig(type, "short_name"))
        end

        def text(value)
          stripped = value.to_s.strip
          stripped.empty? ? nil : stripped
        end
      end
    end
  end
end
