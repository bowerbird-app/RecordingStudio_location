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
              description: Lookups::FORCE_DESCRIPTION
            }
          }
        }.freeze

        OPENAPI = {
          title: "Location - Reverse Geocode",
          summary: "Fill address fields from saved coordinates.",
          description: Lookups.reverse_description,
          parameters: [Lookups::PATH_ID]
        }.freeze

        def self.call(context)
          Errors.wrap do
            Lookups.revise_location(context.recording, actor: context.access_grant.actor) do |location|
              location.reverse!(force: context.params[:force] == true)
            end
          end
        end
      end
    end
  end
end
