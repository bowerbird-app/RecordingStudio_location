# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Attribution
      attr_reader :text

      def self.none
        new
      end

      def initialize(text: nil)
        @text = text.to_s.strip.presence
      end

      def required?
        text.present?
      end

      def as_json(*)
        return if text.blank?

        { "text" => text }
      end
    end
  end
end
