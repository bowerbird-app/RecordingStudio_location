# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Candidate
      attr_reader :id, :label, :name, :raw

      def self.wrap(value)
        return value if value.is_a?(self)
        return new unless value.respond_to?(:to_h)

        new(**value.to_h.symbolize_keys.slice(:id, :label, :name, :raw))
      end

      def initialize(id:, label:, name: nil, raw: nil)
        @id = id.to_s
        @label = label.to_s
        @name = name
        @raw = raw
      end

      def as_json(*)
        { "id" => id, "label" => label, "name" => name }.compact
      end
    end
  end
end
