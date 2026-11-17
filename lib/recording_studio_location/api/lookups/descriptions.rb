# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      GEOCODE_OPENING = [
        "Look up map coordinates for a saved location from its address and save them.",
        "Use this after setting or changing an address, when you need latitude and longitude.",
        "Use location_reverse when the location already has coordinates and you need the address.",
        "Save an address on the location first.",
        "The lookup reads address_line_1, address_line_2, locality, region, postal_code, and country_code.",
        "It writes latitude and longitude only."
      ].join(" ").freeze

      GEOCODE_REVISION = "The new coordinates become a new revision of the location, " \
                         "so the previous coordinates stay in history."

      REVERSE_OPENING = [
        "Fill the address fields of a saved location from its coordinates.",
        "Use this when the location has latitude and longitude and you need the address.",
        "Use location_geocode when the location has an address and you need coordinates.",
        "Save both latitude and longitude on the location first.",
        "Existing address text stays unless force is true.",
        "The lookup fills blank address_line_1, address_line_2, locality, region, postal_code, and country_code.",
        "Only location_geocode writes latitude and longitude."
      ].join(" ").freeze

      REVERSE_REVISION = "The new address becomes a new revision of the location, " \
                         "so the previous address stays in history."

      module_function

      def geocode_description
        [
          GEOCODE_OPENING,
          shared_lookup_warnings,
          GEOCODE_REVISION,
          response_description,
          missing_geocoder_warning,
          blank_address_warning,
          no_coordinates_warning
        ].join(" ")
      end

      def reverse_description
        [
          REVERSE_OPENING,
          shared_lookup_warnings,
          REVERSE_REVISION,
          response_description,
          missing_geocoder_warning,
          missing_coordinates_warning,
          reverse_not_found_warning
        ].join(" ")
      end

      def response_description
        "It returns the updated location. " \
          "The recording fields are #{RECORDING_RESPONSE_FIELDS.join(', ')}. " \
          "The place fields are #{PLACE_RESPONSE_FIELDS.join(', ')}. " \
          "The coordinates field is a latitude and longitude pair, or null when either value is missing."
      end

      def shared_lookup_warnings
        "You need edit access to the location. " \
          "The call uses the host's configured geocoding provider and may cost money."
      end

      def missing_geocoder_warning
        "When no geocoder is configured, the call fails with Missing. " \
          "The response code is invalid_input and the message is " \
          "\"Assign RecordingStudio::Location.geocoder before geocoding\"."
      end

      def blank_address_warning
        "When the saved address is blank, the response code is invalid_input and the message is " \
          "\"Geocoding needs an address\"."
      end

      def no_coordinates_warning
        "When the lookup finds no coordinates, the call fails with NotFound. " \
          "The response code is not_found and the message is \"Geocoding returned no coordinates\", " \
          "or the provider NotFound message."
      end

      def missing_coordinates_warning
        "When latitude or longitude is missing, the response code is invalid_input and the message is " \
          "\"Reverse geocoding needs latitude and longitude\"."
      end

      def reverse_not_found_warning
        "When the lookup finds nothing, the call fails with NotFound. " \
          "The response code is not_found and the message is the provider NotFound message."
      end
    end
  end
end
