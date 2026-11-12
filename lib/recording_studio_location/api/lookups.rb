# frozen_string_literal: true

require_relative "lookups/support"
require_relative "lookups/geocode"
require_relative "lookups/reverse"

module RecordingStudioLocation
  module Api
    module Lookups
      DEFINITIONS = {
        location_geocode: {
          http_verb: :post,
          required_role: :edit,
          path: "location/geocode/:id",
          handler: Geocode,
          serializer: RECORDING_SERIALIZER,
          input_contract: Geocode::CONTRACT,
          openapi: Geocode::OPENAPI
        },
        location_reverse: {
          http_verb: :post,
          required_role: :edit,
          path: "location/reverse/:id",
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
