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
          summary: "Look up coordinates",
          tags: ["Location"],
          description: Lookups.geocode_description,
          parameters: [Lookups::PATH_ID]
        }.freeze

        def self.call(context)
          Errors.wrap do
            Lookups.revise_location(context.recording, actor: context.access_grant.actor, &:geocode!)
          end
        end
      end
    end
  end
end
