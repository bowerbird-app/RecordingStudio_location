# frozen_string_literal: true

module RecordingStudioLocation
  module Map
    # Keyless OpenStreetMap export embed. The iframe loads osm.org; this gem
    # does not fetch tiles itself. Suitable for dummy/dev and moderate host
    # use. Heavy production traffic should use a commercial tile provider or
    # Google Embed.
    class OpenStreetMap < Adapter
      EMBED = "https://www.openstreetmap.org/export/embed.html"

      def preview(latitude: nil, longitude: nil)
        pair = Coordinates.pair(latitude, longitude)
        Preview.new(
          url: pair && fill(*pair),
          url_template: template,
          title: Preview.title_for(pair)
        )
      end

      private

      def template
        "#{EMBED}?bbox={west},{south},{east},{north}&layer=mapnik&marker={lat},{lng}"
      end

      def fill(latitude, longitude)
        west, south, east, north = Coordinates.bbox(latitude, longitude)
        "#{EMBED}?bbox=#{Coordinates.format(west)},#{Coordinates.format(south)}," \
          "#{Coordinates.format(east)},#{Coordinates.format(north)}" \
          "&layer=mapnik&marker=#{Coordinates.format(latitude)},#{Coordinates.format(longitude)}"
      end
    end
  end
end
