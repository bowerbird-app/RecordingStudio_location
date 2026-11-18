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
  #
  # `register_api_endpoints_on` chooses which Recording Studio APIs receive
  # `location_geocode` and `location_reverse`.
  class Configuration
    include IdentityConfiguration

    attr_accessor :geocoder, :map, :authenticate, :lookup_depth
    attr_reader :hooks, :layout, :location_types, :icon_mode, :allowed_icons, :default_icon,
                :register_api_endpoints_on

    def initialize
      @geocoder = @map = @authenticate = @layout = nil
      @lookup_depth = :full
      @hooks = RecordingStudio::Hooks.new
      @location_types = DEFAULT_LOCATION_TYPES.dup
      @icon_mode = :type
      @allowed_icons = DEFAULT_ALLOWED_ICONS.dup
      @default_icon = DEFAULT_ICON
      @register_api_endpoints_on = :all
    end

    def to_h
      identity_settings.merge(
        geocoder: geocoder,
        map: map,
        authenticate: authenticate,
        layout: layout,
        lookup_depth: lookup_depth,
        register_api_endpoints_on: register_api_endpoints_on,
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

    def layout=(value)
      @layout = RecordingStudio::Layout.accept(value)
    end

    def register_api_endpoints_on=(value)
      @register_api_endpoints_on = normalize_register_api_endpoints_on(value)
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

    def normalize_register_api_endpoints_on(value)
      return :all if every_api?(value)
      return [].freeze if [false, []].include?(value)

      api_name_list(value)
    end

    def every_api?(value)
      value == :all || api_name_token(value)&.casecmp("all")&.zero?
    end

    def api_name_list(value)
      unless value.is_a?(Array)
        raise ArgumentError, "register_api_endpoints_on must be :all, false, or a list of API names"
      end

      value.map { |name| required_api_name(name) }.freeze
    end

    def api_name_token(value)
      return unless value.is_a?(String) || value.is_a?(Symbol)

      value.to_s.strip
    end

    def required_api_name(name)
      text = api_name_token(name)
      raise ArgumentError, "register_api_endpoints_on names must be strings or symbols" if text.nil?
      raise ArgumentError, "register_api_endpoints_on name is blank" if text.empty?

      text
    end
  end
end
