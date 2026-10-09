# frozen_string_literal: true

module RecordingStudioLocation
  module Map
    class Preview
      attr_reader :url, :url_template, :title

      def initialize(url_template:, title:, url: nil)
        @url = url.to_s.strip.presence
        @url_template = url_template.to_s
        @title = title.to_s
      end

      def visible?
        url.present?
      end

      def self.title_for(pair)
        if pair
          I18n.t(
            "recording_studio_location.map.title_with_coordinates",
            latitude: Coordinates.format(pair[0]),
            longitude: Coordinates.format(pair[1])
          )
        else
          I18n.t("recording_studio_location.map.title")
        end
      end
    end
  end
end
