# frozen_string_literal: true

module RecordingStudioLocation
  module Map
    # Provider-agnostic map preview. Hosts assign an instance to
    # +RecordingStudioLocation.configuration.map+. Built-in Google Embed and
    # OpenStreetMap implement this surface. The search UI only reads a URL
    # template with {lat}/{lng} (and optional bbox) placeholders.
    class Adapter
      def enabled?
        true
      end

      def preview(latitude: nil, longitude: nil)
        raise NotImplementedError, "#{self.class}#preview must be implemented"
      end
    end
  end
end
