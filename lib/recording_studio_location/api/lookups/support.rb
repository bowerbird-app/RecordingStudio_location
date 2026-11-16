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

      def revise_location(recording, actor:, &)
        (recording.root_recording || recording).revise(recording, actor:, &)
      end
    end
  end
end
