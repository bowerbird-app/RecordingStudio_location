# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    module Errors
      module_function

      def wrap
        yield
      rescue RecordingStudioLocation::Geocoder::QueryError, RecordingStudioLocation::Geocoder::Missing => e
        raise ::RecordingStudioApi::InvalidActionInputError, e.message
      rescue RecordingStudioLocation::Geocoder::NotFound => e
        raise ::RecordingStudioApi::NotFoundError, e.message
      end
    end
  end
end
