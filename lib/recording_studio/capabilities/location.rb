# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    # Host opt-in for placing a Location recording under a recordable type.
    #
    # Installing this gem registers `:location` and its child recordable. It does
    # not choose parent types. A host enables the capability on each recordable
    # that may contain a place:
    #
    #   include RecordingStudio::Capabilities::Location.to
    #
    # `.to` wraps RecordingStudio::Capabilities.include_for. It does not register
    # the capability and it does not list application-specific parents.
    module Location
      def self.to(**)
        RecordingStudio::Capabilities.include_for(:location, **)
      end
    end
  end
end
