# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      class PlaceSearch
        CONTRACT = {
          reject_unknown: false,
          fields: {
            query: {
              type: :string,
              required: true,
              allow_blank: false,
              description: "Place or address to search for."
            },
            session: {
              type: :string,
              description: "Optional search session token for the place adapter."
            }
          }
        }.freeze

        OPENAPI = {
          title: "Location - Search Places",
          summary: "Search for places",
          description: "Return place candidates for a query. Does not save a location. " \
                       "Calls the host geocoder provider (paid traffic). " \
                       "Authorize :view on the request root."
        }.freeze

        def self.call(context)
          Errors.wrap do
            Lookups.authorize!(context, recording: Lookups.view_recording(context), role: :view)
            Lookups.search_payload(context.params[:query], session: context.params[:session])
          end
        end
      end
    end
  end
end
