# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      RECORDING_SERIALIZER = lambda do |recording, **kwargs|
        ::RecordingStudioApi::Serializers::RecordingSerializer.call(
          recording,
          version: kwargs[:version] || "v1",
          api: kwargs[:api] || :public
        ).merge(recording.recordable.api_payload)
      end

      module_function

      def authorize!(context, recording:, role:)
        raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if recording.nil?

        context.access_grant.authorize!(recording:, role:)
      end

      def location_recording(context)
        recording = context.access_grant.accessible_recordings.find_by(
          id: context.params[:id],
          recordable_type: RecordingStudioLocation::Api::TYPE
        )
        raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if recording.nil?

        recording
      end

      def revise_location(recording, actor:, &)
        (recording.root_recording || recording).revise(recording, actor:, &)
      end
    end
  end
end
