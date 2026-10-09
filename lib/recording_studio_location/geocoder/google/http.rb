# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"

module RecordingStudioLocation
  module Geocoder
    class Google
      class Http
        OPEN_TIMEOUT = 5
        READ_TIMEOUT = 10

        def initialize(api_key:, http: nil)
          @api_key = api_key
          @http = http
        end

        def get(endpoint, params)
          uri = request_uri(endpoint, params)
          response = perform_request(uri)
          parse_json(response, uri)
        end

        def ok_payload?(payload)
          payload["status"].to_s == "OK"
        end

        def zero_results?(payload)
          %w[ZERO_RESULTS NOT_FOUND].include?(payload["status"].to_s)
        end

        def assert_ok!(payload, uri)
          return if ok_payload?(payload)
          raise NotFound, "No geocoding result for #{safe_uri(uri)}" if zero_results?(payload)

          raise RequestError, "Geocoding #{payload['status']} for #{safe_uri(uri)}"
        end

        def request_uri(endpoint, params)
          uri = URI(endpoint)
          uri.query = URI.encode_www_form(params.merge(key: @api_key))
          uri
        end

        def safe_uri(uri)
          filtered = uri.dup
          params = URI.decode_www_form(filtered.query.to_s).to_h.except("key")
          filtered.query = URI.encode_www_form(params)
          filtered.to_s
        end

        private

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

        def response_code(response)
          response.respond_to?(:code) ? response.code : "unknown"
        end
      end
    end
  end
end
