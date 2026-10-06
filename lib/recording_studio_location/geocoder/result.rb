# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Result
      ADDRESS_ATTRIBUTES = %i[
        address_line_1
        address_line_2
        locality
        region
        postal_code
        country_code
      ].freeze

      attr_reader :latitude, :longitude, :formatted_address, :raw, *ADDRESS_ATTRIBUTES

      def self.wrap(value)
        return value if value.is_a?(self)
        return new unless value.respond_to?(:to_h)

        new(**value.to_h.symbolize_keys.slice(:latitude, :longitude, :formatted_address, :raw, *ADDRESS_ATTRIBUTES))
      end

      def initialize(latitude: nil, longitude: nil, formatted_address: nil, raw: nil, **address)
        @latitude = latitude
        @longitude = longitude
        @formatted_address = formatted_address
        @raw = raw
        ADDRESS_ATTRIBUTES.each do |attribute|
          instance_variable_set(:"@#{attribute}", address[attribute])
        end
      end

      def coordinates
        return if latitude.nil? || longitude.nil?

        [latitude.to_f, longitude.to_f]
      end
    end
  end
end
