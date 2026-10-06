# frozen_string_literal: true

module RecordingStudio
  module Location
    # A place that can sit anywhere a host allows in a Recording Studio tree.
    #
    # The recordable is not a root. It does not name parent models. Hosts enable
    # RecordingStudio::Capabilities::Location on the recordables that may contain
    # one or more Location recordings.
    #
    # Coordinates are optional. Geocoding runs only when you call geocode! or
    # reverse! with an adapter assigned to RecordingStudio::Location.geocoder.
    class Location < ActiveRecord::Base
      include Formatting
      include RecordingStudio::Location::Geocoding

      self.table_name = "recording_studio_locations"

      recording_studio_recordable label: "Location", plural_label: "Locations", root: false

      STRING_ATTRIBUTES = %i[
        name
        address_line_1
        address_line_2
        locality
        region
        postal_code
      ].freeze

      before_validation :normalize_location

      validates :name, :address_line_1, :address_line_2, :locality, :region, :postal_code,
                length: { maximum: 255 },
                allow_blank: true
      validates :country_code,
                format: {
                  with: /\A[A-Z]{2}\z/,
                  message: "must be a two-letter ISO country code"
                },
                allow_blank: true
      validates :latitude,
                numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 },
                allow_nil: true
      validates :longitude,
                numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 },
                allow_nil: true
      validate :coordinates_are_numeric

      def self.model_name
        ActiveModel::Name.new(self, nil, "Location")
      end

      def recordable_name
        display_name
      end

      private

      def normalize_location
        normalize_strings
        normalize_country_code
        clear_blank_coordinate(:latitude)
        clear_blank_coordinate(:longitude)
      end

      def normalize_strings
        STRING_ATTRIBUTES.each do |attribute|
          value = public_send(attribute)
          next if value.nil?

          public_send(:"#{attribute}=", value.to_s.strip.presence)
        end
      end

      def normalize_country_code
        return if country_code.nil?

        self.country_code = country_code.to_s.strip.upcase.presence
      end

      def clear_blank_coordinate(attribute)
        raw = public_send(:"#{attribute}_before_type_cast")
        return unless raw.is_a?(String) && raw.strip.empty?

        public_send(:"#{attribute}=", nil)
      end

      def coordinates_are_numeric
        validate_coordinate_number(:latitude)
        validate_coordinate_number(:longitude)
      end

      def validate_coordinate_number(attribute)
        raw = public_send(:"#{attribute}_before_type_cast")
        return if raw.nil? || raw.is_a?(Numeric)
        return if raw.is_a?(String) && raw.strip.empty?
        return if decimal?(raw)

        errors.add(attribute, "must be a number")
      end

      def decimal?(value)
        BigDecimal(value.to_s)
        true
      rescue ArgumentError
        false
      end
    end
  end
end
