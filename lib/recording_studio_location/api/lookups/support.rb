# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Lookups
      PASSTHROUGH = ->(result, **) { result }
      RECORDING_SERIALIZER = lambda do |recording, **kwargs|
        ::RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(
          recording,
          version: kwargs[:version] || "v1",
          api: kwargs[:api] || :public
        )
      end

      module_function

      def authorize!(context, recording:, role:)
        raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if recording.nil?

        context.access_grant.authorize!(recording:, role:)
      end

      def view_recording(context)
        return context.recording if recording_present?(context)

        context.root_recording
      end

      def location_recording(context)
        return context.recording if recording_present?(context)

        recording = context.access_grant.accessible_recordings.find_by(
          id: context.params[:id],
          recordable_type: RecordingStudioLocation::Api::TYPE
        )
        raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if recording.nil?

        recording
      end

      def recording_present?(context)
        context.respond_to?(:recording) && context.recording
      end

      def adapter
        RecordingStudio::Location.geocoder
      end

      def search_payload(query, session:)
        results = RecordingStudioLocation::PlaceSearch.new(adapter:).candidates(query, session:)
        {
          results: results.map { |candidate| RecordingStudioLocation::Geocoder::Candidate.wrap(candidate).as_json },
          attribution: attribution_payload
        }
      end

      def details_payload(place_id, lookup:, session:)
        result = RecordingStudioLocation::PlaceLookup.new(adapter:).result(
          place_id,
          depth: lookup.presence || RecordingStudioLocation.configuration.lookup_depth,
          session:
        )
        RecordingStudioLocation::Geocoder::Result.wrap(result).as_json
      end

      def attribution_payload
        return unless adapter.respond_to?(:attribution)

        value = adapter.attribution
        text = value.respond_to?(:text) ? value.text : value
        RecordingStudioLocation::Geocoder::Attribution.new(text:).as_json
      end

      def revise_location(recording, actor:, &)
        (recording.root_recording || recording).revise(recording, actor:, &)
      end
    end
  end
end
