# frozen_string_literal: true

module RecordingStudioLocation
  class ApplicationController < ActionController::Base
    include Authentication

    protect_from_forgery with: :exception

    recording_studio_layout { RecordingStudioLocation.configuration.layout }
  end
end
