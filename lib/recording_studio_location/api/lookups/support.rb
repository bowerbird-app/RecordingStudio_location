# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      RECORDING_ID_DESCRIPTION = "The id of the Location recording, as returned when the location was " \
                                 "created or listed."

      RECORDING_RESPONSE_FIELDS = %w[id type parent_id root_id created_at updated_at].freeze

      PLACE_RESPONSE_FIELDS = %w[
        title location_type icon name address_line_1 address_line_2 locality region
        postal_code country_code latitude longitude resolved_icon display_name full_address coordinates
      ].freeze

      PATH_ID = {
        name: "id",
        in: "path",
        description: RECORDING_ID_DESCRIPTION
      }.freeze

      FORCE_DESCRIPTION = "Pass true to replace address text that is already saved. " \
                          "Omit it, or pass false, to keep that text and fill only blank address fields. " \
                          "You send this boolean with the call."

      RECORDING_SERIALIZER = lambda do |recording, **kwargs|
        ::RecordingStudioApi::Serializers::RecordingSerializer.call(
          recording,
          version: kwargs[:version] || "v1",
          api: kwargs[:api] || :public
        ).merge(recording.recordable.api_payload)
      end

      module_function

      def revise_location(recording, actor:, &)
        (recording.root_recording || recording).revise(recording, actor:, &)
      end
    end
  end
end
