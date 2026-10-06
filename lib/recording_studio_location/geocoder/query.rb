# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Query
      LOCATION_FIELDS = %i[
        address_line_1
        address_line_2
        locality
        region
        postal_code
      ].freeze

      def self.from(query_or_location)
        new(query_or_location).to_s
      end

      def initialize(query_or_location)
        @query_or_location = query_or_location
      end

      def to_s
        return @query_or_location.to_s.strip unless location?

        (LOCATION_FIELDS.map { |field| text(@query_or_location.public_send(field)) } + [country]).compact.join(", ")
      end

      private

      def location?
        LOCATION_FIELDS.all? { |field| @query_or_location.respond_to?(field) } &&
          @query_or_location.respond_to?(:country_code)
      end

      def country
        code = text(@query_or_location.country_code)&.upcase
        return if code.nil?

        RecordingStudio::Location.country_name(code) || code
      end

      def text(value)
        stripped = value.to_s.strip
        stripped.empty? ? nil : stripped
      end
    end
  end
end
