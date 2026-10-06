# frozen_string_literal: true

module RecordingStudio
  module Location
    # Explicit geocoding on a Location. Forward fills coordinates only. Reverse
    # fills blank address fields. Call these inside +record+ / +revise+.
    module Geocoding
      ADDRESS_FIELDS = %i[
        address_line_1
        address_line_2
        locality
        region
        postal_code
        country_code
      ].freeze

      def geocode!
        adapter = require_geocoder!
        query = RecordingStudioLocation::Geocoder::Query.from(self)
        raise RecordingStudioLocation::Geocoder::QueryError, "Geocoding needs an address" if query.empty?

        apply_forward!(adapter.geocode(self))
        self
      end

      def reverse!(force: false)
        adapter = require_geocoder!
        if latitude.nil? || longitude.nil?
          raise RecordingStudioLocation::Geocoder::QueryError, "Reverse geocoding needs latitude and longitude"
        end

        apply_reverse!(adapter.reverse(latitude, longitude), force: force)
        self
      end

      private

      def require_geocoder!
        adapter = RecordingStudio::Location.geocoder
        return adapter if adapter

        raise RecordingStudioLocation::Geocoder::Missing,
              "Assign RecordingStudio::Location.geocoder before geocoding"
      end

      def apply_forward!(result)
        result = RecordingStudioLocation::Geocoder::Result.wrap(result)
        if result.latitude.nil? || result.longitude.nil?
          raise RecordingStudioLocation::Geocoder::NotFound, "Geocoding returned no coordinates"
        end

        self.latitude = result.latitude
        self.longitude = result.longitude
      end

      def apply_reverse!(result, force:)
        result = RecordingStudioLocation::Geocoder::Result.wrap(result)

        ADDRESS_FIELDS.each do |field|
          value = result.public_send(field)
          next if value.blank?
          next unless force || public_send(field).blank?

          public_send(:"#{field}=", value)
        end
      end
    end
  end
end
