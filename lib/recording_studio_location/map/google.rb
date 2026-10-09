# frozen_string_literal: true

require "cgi"

module RecordingStudioLocation
  module Map
    # Google Maps Embed API. The key is a browser key and appears in the iframe
    # URL. Restrict it by HTTP referrer. Never reuse the server Geocoding key.
    class Google < Adapter
      REQUIRES_BROWSER_KEY = true
      PLACE_EMBED = "https://www.google.com/maps/embed/v1/place"

      def initialize(browser_api_key:)
        super()
        key = browser_api_key.to_s.strip
        raise ArgumentError, "Map browser_api_key is missing" if key.empty?

        @browser_api_key = key
      end

      def preview(latitude: nil, longitude: nil)
        pair = Coordinates.pair(latitude, longitude)
        Preview.new(
          url: pair && fill(pair[0], pair[1]),
          url_template: template,
          title: Preview.title_for(pair)
        )
      end

      private

      def template
        "#{PLACE_EMBED}?key=#{escaped_key}&q={lat},{lng}"
      end

      def fill(latitude, longitude)
        "#{PLACE_EMBED}?key=#{escaped_key}&q=#{Coordinates.format(latitude)},#{Coordinates.format(longitude)}"
      end

      def escaped_key
        CGI.escape(@browser_api_key)
      end
    end
  end
end
