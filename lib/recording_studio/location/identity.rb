# frozen_string_literal: true

module RecordingStudio
  module Location
    # User title, host type, and icon on a Location. name stays the venue.
    module Identity
      TITLE_MAX_LENGTH = 80

      def resolved_icon
        RecordingStudioLocation.configuration.resolved_icon(
          stored_icon: icon,
          location_type: location_type
        )
      end

      def location_type_label
        return if location_type.blank?

        RecordingStudioLocation.configuration.location_type_label(location_type)
      end

      def api_payload
        self.class::PERMITTED_ATTRIBUTES.index_with { |attribute| public_send(attribute) }.merge(
          resolved_icon: resolved_icon,
          display_name: display_name,
          full_address: full_address,
          coordinates: coordinates
        )
      end

      private

      def clear_icon_unless_choose
        return if RecordingStudioLocation.configuration.icon_mode_choose?

        self.icon = nil
      end
    end

    module IdentityValidations
      extend ActiveSupport::Concern

      included do
        validates :title, length: { maximum: Identity::TITLE_MAX_LENGTH }, allow_blank: true
        validates :location_type,
                  inclusion: {
                    in: ->(_) { RecordingStudioLocation.configuration.location_type_keys },
                    message: "is not in the list of types"
                  },
                  allow_blank: true
        validates :icon,
                  inclusion: {
                    in: ->(_) { RecordingStudioLocation.configuration.allowed_icons },
                    message: "is not in the list of icons"
                  },
                  allow_blank: true
      end
    end
  end
end
