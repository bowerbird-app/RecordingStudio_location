# frozen_string_literal: true

module RecordingStudioLocation
  module Map
    class Fake < Adapter
      def initialize(url_template: "https://map.test/embed?lat={lat}&lng={lng}")
        super()
        @url_template = url_template
      end

      def preview(latitude: nil, longitude: nil)
        pair = Coordinates.pair(latitude, longitude)
        Preview.new(
          url: pair && fill(*pair),
          url_template: @url_template,
          title: "Map test"
        )
      end

      private

      def fill(latitude, longitude)
        @url_template
          .gsub("{lat}", Coordinates.format(latitude))
          .gsub("{lng}", Coordinates.format(longitude))
      end
    end
  end
end
