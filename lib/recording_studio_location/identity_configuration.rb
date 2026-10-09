# frozen_string_literal: true

module RecordingStudioLocation
  # Title, type, and icon settings for Location.
  module IdentityConfiguration
    ICON_MODES = %i[type choose none].freeze

    DEFAULT_LOCATION_TYPES = {
      office: { label: "Office", icon: "building-office" },
      home: { label: "Home", icon: "home" },
      venue: { label: "Venue", icon: "map-pin" },
      other: { label: "Other", icon: "map-pin" }
    }.freeze

    DEFAULT_ALLOWED_ICONS = %w[home building-office map-pin star briefcase].freeze
    DEFAULT_ICON = "map-pin"

    def location_types=(value)
      @location_types = normalize_location_types(value)
    end

    def icon_mode=(value)
      mode = value.to_s.strip.to_sym
      @icon_mode = ICON_MODES.include?(mode) ? mode : :type
    end

    def allowed_icons=(value)
      @allowed_icons = Array(value).map { |name| name.to_s.strip.presence }.compact
    end

    def default_icon=(value)
      @default_icon = value.to_s.strip.presence || DEFAULT_ICON
    end

    def icon_mode_type?
      icon_mode == :type
    end

    def icon_mode_choose?
      icon_mode == :choose
    end

    def icon_mode_none?
      icon_mode == :none
    end

    def location_type_keys
      location_types.keys.map(&:to_s)
    end

    def location_type_config(key)
      return if key.blank?

      location_types[key.to_sym] || location_types[key.to_s]
    end

    def location_type_label(key)
      fallback = location_type_config(key)&.fetch(:label, nil).presence || key.to_s.humanize
      return fallback unless defined?(I18n)

      I18n.t("recording_studio_location.location_types.#{key}", default: fallback)
    end

    def icon_for_type(key)
      location_type_config(key)&.fetch(:icon, nil).to_s.strip.presence
    end

    # Stored icon wins, even if the host later removed it from allowed_icons.
    # A type removed from location_types is skipped. default_icon is last.
    def resolved_icon(stored_icon: nil, location_type: nil)
      stored = stored_icon.to_s.strip.presence
      return stored if stored.present?

      type_icon = icon_for_type(location_type)
      return type_icon if type_icon.present?

      default_icon.to_s.strip.presence
    end

    def location_type_radio_options
      location_types.keys.map do |key|
        {
          label: location_type_label(key),
          value: key.to_s,
          icon: icon_for_type(key)
        }
      end
    end

    def allowed_icon_radio_options
      allowed_icons.map do |name|
        {
          label: icon_label(name),
          value: name,
          icon: name
        }
      end
    end

    def icon_label(name)
      fallback = name.to_s.tr("-", " ").humanize
      return fallback unless defined?(I18n)

      I18n.t("recording_studio_location.icons.#{name}", default: fallback)
    end

    def type_icon_map
      location_types.each_with_object({}) do |(key, config), acc|
        icon = config[:icon].to_s.strip.presence
        acc[key.to_s] = icon if icon
      end
    end

    private

    def normalize_location_types(value)
      hash = value.respond_to?(:to_h) ? value.to_h : {}
      hash.each_with_object({}) do |(key, config), acc|
        details = config.respond_to?(:to_h) ? config.to_h : {}
        acc[key.to_sym] = {
          label: (details[:label] || details["label"]).to_s,
          icon: (details[:icon] || details["icon"]).to_s
        }
      end
    end
  end
end
