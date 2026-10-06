# frozen_string_literal: true

require "bigdecimal"

module RecordingStudio
  module Location
    # Presentation helpers for a place. Blank pieces are omitted so partial
    # addresses do not render as strings of commas.
    module Formatting
      def display_name
        text(name) ||
          place_line.presence ||
          text(address_line_1) ||
          text(address_line_2) ||
          full_address.presence ||
          coordinates_label ||
          "Location"
      end

      def full_address
        [
          text(address_line_1),
          text(address_line_2),
          locality_line.presence,
          country_name
        ].compact.join(", ")
      end

      # [latitude, longitude] when both values are present, otherwise nil.
      # Zero is a real coordinate. A single missing value is not returned.
      def coordinates
        return if latitude.nil? || longitude.nil?

        [latitude.to_f, longitude.to_f]
      end

      def coordinates_label
        return if latitude.nil? || longitude.nil?

        [latitude, longitude].map { |number| format_coordinate(number) }.join(", ")
      end

      def country_name
        code = text(country_code)
        return if code.nil?

        RecordingStudio::Location.country_name(code)
      end

      private

      def place_line
        [text(locality), text(region), country_name].compact.join(", ")
      end

      def locality_line
        [text(locality), text(region), text(postal_code)].compact.join(" ")
      end

      def text(value)
        stripped = value.to_s.strip
        stripped.empty? ? nil : stripped
      end

      def format_coordinate(number)
        BigDecimal(number.to_s).to_s("F").sub(/\.?0+\z/, "")
      end
    end
  end
end
