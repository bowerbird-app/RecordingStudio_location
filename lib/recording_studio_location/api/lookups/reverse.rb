# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      class Reverse
        CONTRACT = {
          reject_unknown: false,
          fields: {
            force: {
              type: :boolean,
              description: "Overwrite address fields that already have text."
            }
          }
        }.freeze

        OPENAPI = {
          title: "Location - Reverse Geocode",
          summary: "Fill blank address fields from coordinates",
          description: "Call reverse! inside a location revision. Blank address fields are filled. " \
                       "Pass force to overwrite text that is already there. " \
                       "Calls the host geocoder provider (paid traffic). Authorize :edit on the location."
        }.freeze

        def self.call(context)
          Errors.wrap do
            recording = Lookups.location_recording(context)
            Lookups.authorize!(context, recording:, role: :edit)
            Lookups.revise_location(recording, actor: context.access_grant.actor) do |location|
              location.reverse!(force: context.params[:force] == true)
            end
          end
        end
      end
    end
  end
end
