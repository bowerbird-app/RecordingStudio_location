# frozen_string_literal: true

module RecordingStudioLocation
  # Host configuration for Location.
  #
  # `geocoder` is a reserved adapter slot. This version stores the object and
  # never calls it, so addresses are not sent to an external service.
  class Configuration
    attr_accessor :geocoder
    attr_reader :hooks

    def initialize
      @geocoder = nil
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        geocoder: geocoder,
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
