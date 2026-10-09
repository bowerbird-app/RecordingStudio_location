# frozen_string_literal: true

require_relative "identity_configuration"

module RecordingStudioLocation
  # Host configuration for Location.
  #
  # `geocoder` is the optional adapter used by Location#geocode!, #reverse!,
  # and the search endpoints. `map` is a separate optional adapter for the
  # pin preview under search fields. Leave either nil when the host has no
  # provider. Saving a location never contacts a network service.
  #
  # Title, type, and icon are host-facing labels on a place. `name` stays the
  # venue the search fills. In `:type` icon mode the stored `icon` column is
  # left blank and `resolved_icon` reads the type's icon, then `default_icon`.
  class Configuration
    include IdentityConfiguration

    attr_accessor :geocoder, :map, :authenticate, :lookup_depth
    attr_reader :hooks, :location_types, :icon_mode, :allowed_icons, :default_icon

    def initialize
      @geocoder = nil
      @map = nil
      @authenticate = nil
      @lookup_depth = :full
      @hooks = RecordingStudio::Hooks.new
      @location_types = DEFAULT_LOCATION_TYPES.dup
      @icon_mode = :type
      @allowed_icons = DEFAULT_ALLOWED_ICONS.dup
      @default_icon = DEFAULT_ICON
    end

    def to_h
      identity_settings.merge(
        geocoder: geocoder,
        map: map,
        authenticate: authenticate,
        lookup_depth: lookup_depth,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      )
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end

    private

    def identity_settings
      {
        location_types: location_types,
        icon_mode: icon_mode,
        allowed_icons: allowed_icons,
        default_icon: default_icon
      }
    end
  end
end
