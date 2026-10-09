# frozen_string_literal: true

module RecordingStudioLocation
  # Host configuration for Location.
  #
  # `geocoder` is the optional adapter used by Location#geocode!, #reverse!,
  # and the search endpoints. `map` is a separate optional adapter for the
  # pin preview under search fields. Leave either nil when the host has no
  # provider. Saving a location never contacts a network service.
  class Configuration
    attr_accessor :geocoder, :map, :authenticate, :lookup_depth
    attr_reader :hooks

    def initialize
      @geocoder = nil
      @map = nil
      @authenticate = nil
      @lookup_depth = :full
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        geocoder: geocoder,
        map: map,
        authenticate: authenticate,
        lookup_depth: lookup_depth,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end
  end
end
