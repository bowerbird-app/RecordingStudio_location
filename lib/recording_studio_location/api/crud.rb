# frozen_string_literal: true

module RecordingStudioLocation
  module Api
    # Recording Studio API treats operations: [] as the default CRUD set
    # (Array(value).presence || DEFAULT_OPERATIONS). These handlers keep Location
    # tree CRUD off the HTTP surface until that gem can represent an empty set.
    module Crud
      OPERATIONS = %i[index show create update destroy].freeze

      class Reject
        def self.call(_context)
          raise ::RecordingStudioApi::UnsupportedActionError, "Location CRUD is not on this resource"
        end
      end
    end
  end
end
