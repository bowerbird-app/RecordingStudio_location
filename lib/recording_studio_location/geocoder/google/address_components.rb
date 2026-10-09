# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Google
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
