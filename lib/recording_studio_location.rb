# frozen_string_literal: true

require "recording_studio"
require "recording_studio_location/version"
require "recording_studio_location/copy"
require "recording_studio_location/configuration"
require "recording_studio_location/engine"
require "recording_studio_location/geocoder"
require "recording_studio_location/map"
require "recording_studio_location/place_search"
require "recording_studio_location/place_lookup"
require "recording_studio/capabilities/location"
require "recording_studio/location"

module RecordingStudioLocation
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
