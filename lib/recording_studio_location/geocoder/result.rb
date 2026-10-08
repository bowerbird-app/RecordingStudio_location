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

      attr_reader :name, :latitude, :longitude, :formatted_address, :raw, *ADDRESS_ATTRIBUTES

      def self.wrap(value)
        return value if value.is_a?(self)
        return new unless value.respond_to?(:to_h)

        attrs = value.to_h.symbolize_keys.slice(
          :name, :latitude, :longitude, :formatted_address, :raw, *ADDRESS_ATTRIBUTES
        )
        new(**attrs)
      end

      def initialize(**attrs)
        @name = attrs[:name]
        @latitude = attrs[:latitude]
        @longitude = attrs[:longitude]
        @formatted_address = attrs[:formatted_address]
        @raw = attrs[:raw]
        ADDRESS_ATTRIBUTES.each do |attribute|
          instance_variable_set(:"@#{attribute}", attrs[attribute])
        end
      end

      def coordinates
        return if latitude.nil? || longitude.nil?

        [latitude.to_f, longitude.to_f]
      end

      def as_json(*)
        {
          "name" => name,
          **ADDRESS_ATTRIBUTES.to_h { |attribute| [attribute.to_s, public_send(attribute)] },
          "latitude" => latitude,
          "longitude" => longitude,
          "formatted_address" => formatted_address
        }
      end
    end
  end
end
