# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    module LookupDepth
      FULL = :full
      ADDRESS = :address
      VALUES = [FULL, ADDRESS].freeze
      DEFAULT = FULL

      module_function

      def normalize(value)
        name = value.to_s.strip.downcase.to_sym
        VALUES.include?(name) ? name : DEFAULT
      end

      def supported_by?(adapter, depth)
        caps = adapter.respond_to?(:capabilities) ? adapter.capabilities : {}
        depths = Array(caps[:lookup_depths] || caps["lookup_depths"]).map { |item| normalize(item) }
        depths.include?(normalize(depth))
      end
    end
  end
end
