# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      class PlaceDetails
        CONTRACT = {
          reject_unknown: false,
          fields: {
            place_id: {
              type: :string,
              required: true,
              allow_blank: false,
              description: "Place id from a search result."
            },
            lookup: {
              type: :string,
              enum: RecordingStudioLocation::Geocoder::LookupDepth::VALUES.map(&:to_s),
              description: "How much detail to load: full or address."
            },
            session: {
              type: :string,
              description: "Optional search session token for the place adapter."
            }
          }
        }.freeze

        OPENAPI = {
          title: "Location - Place Details",
          summary: "Load place details",
          description: "Return structured address fields for a place id from search. " \
                       "Does not save a location. Calls the host geocoder provider (paid traffic). " \
                       "Authorize :view on the request root."
        }.freeze

        def self.call(context)
          Errors.wrap do
            Lookups.authorize!(context, recording: Lookups.view_recording(context), role: :view)
            Lookups.details_payload(
              context.params[:place_id],
              lookup: context.params[:lookup],
              session: context.params[:session]
            )
          end
        end
      end
    end
  end
end
