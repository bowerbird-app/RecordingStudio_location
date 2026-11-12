# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      class Geocode
        CONTRACT = {
          reject_unknown: false,
          fields: {}
        }.freeze

        OPENAPI = {
          title: "Location - Geocode",
          summary: "Fill coordinates from the address",
          description: "Call geocode! inside a location revision. Writes latitude and longitude only. " \
                       "Calls the host geocoder provider (paid traffic). Authorize :edit on the location."
        }.freeze

        def self.call(context)
          Errors.wrap do
            recording = Lookups.location_recording(context)
            Lookups.authorize!(context, recording:, role: :edit)
            Lookups.revise_location(recording, actor: context.access_grant.actor, &:geocode!)
          end
        end
      end
    end
  end
end
