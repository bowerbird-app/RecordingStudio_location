# frozen_string_literal: true

module RecordingStudioLocation
  module Map
    module Coordinates
      module_function

      SPAN = 0.012

      def pair(latitude, longitude)
        lat = to_float(latitude)
        lng = to_float(longitude)
        return unless lat&.between?(-90.0, 90.0) && lng&.between?(-180.0, 180.0)

        [lat, lng]
      end

      def bbox(latitude, longitude, span: SPAN)
        lat, lng = pair(latitude, longitude)
        return unless lat

        [
          (lng - span).clamp(-180.0, 180.0),
          (lat - span).clamp(-90.0, 90.0),
          (lng + span).clamp(-180.0, 180.0),
          (lat + span).clamp(-90.0, 90.0)
        ]
      end

      def format(value)
        Kernel.format("%.6f", Float(value))
      end

      def to_float(value)
        return if value.nil?
        return if value.is_a?(String) && value.strip.empty?

        Float(value)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
