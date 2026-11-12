# frozen_string_literal: true

require_relative "lookups/support"
require_relative "lookups/place_search"
require_relative "lookups/place_details"
require_relative "lookups/geocode"
require_relative "lookups/reverse"

module RecordingStudioLocation
  module Api
    module Lookups
      DEFINITIONS = {
        place_search: {
          http_verb: :get,
          required_role: :view,
          path: "location/place_search",
          handler: PlaceSearch,
          serializer: PASSTHROUGH,
          input_contract: PlaceSearch::CONTRACT,
          openapi: PlaceSearch::OPENAPI
        },
        place_details: {
          http_verb: :get,
          required_role: :view,
          path: "location/place_details",
          handler: PlaceDetails,
          serializer: PASSTHROUGH,
          input_contract: PlaceDetails::CONTRACT,
          openapi: PlaceDetails::OPENAPI
        },
        geocode: {
          http_verb: :post,
          required_role: :edit,
          path: "locations/:id/geocode",
          handler: Geocode,
          serializer: RECORDING_SERIALIZER,
          input_contract: Geocode::CONTRACT,
          openapi: Geocode::OPENAPI
        },
        reverse: {
          http_verb: :post,
          required_role: :edit,
          path: "locations/:id/reverse",
          handler: Reverse,
          serializer: RECORDING_SERIALIZER,
          input_contract: Reverse::CONTRACT,
          openapi: Reverse::OPENAPI
        }
      }.freeze

      module_function

      def definition(name)
        DEFINITIONS.fetch(name)
      end
    end
  end
end
