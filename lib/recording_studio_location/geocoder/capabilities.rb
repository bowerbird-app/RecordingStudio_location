# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    module Capabilities
      module_function

      def searchable?(adapter)
        enabled?(adapter, :search)
      end

      def details?(adapter)
        enabled?(adapter, :details)
      end

      def enabled?(adapter, name)
        return false unless adapter

        caps = adapter.respond_to?(:capabilities) ? adapter.capabilities : {}
        caps[name] == true || caps[name.to_s] == true
      end
    end
  end
end
