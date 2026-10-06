# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Adapter
      def geocode(_query_or_location)
        raise NotImplementedError, "#{self.class}#geocode must be implemented"
      end

      def reverse(_latitude, _longitude)
        raise NotImplementedError, "#{self.class}#reverse must be implemented"
      end
    end
  end
end
