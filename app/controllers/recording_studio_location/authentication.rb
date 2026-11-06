# frozen_string_literal: true

module RecordingStudioLocation
  module Authentication
    extend ActiveSupport::Concern

    included do
      include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    end

    private

    def authenticate_location_request!
      authenticate_location_identity!
      return if performed?

      authorize_location_search!
    end

    def authenticate_location_identity!
      callback = RecordingStudioLocation.configuration.authenticate
      if callback.respond_to?(:call)
        invoke_authenticate_callback(callback)
        return
      end

      if respond_to?(:authenticate_user!, true)
        authenticate_user!
        return
      end

      head :unauthorized
    end

    def authorize_location_search!
      unless RecordingStudioLocation.accessible_available?
        head :forbidden
        return
      end

      actor = location_request_actor
      unless actor
        head :unauthorized
        return
      end

      authorize_location_search_recording(actor)
    end

    def authorize_location_search_recording(actor)
      recording = location_search_recording_for(actor)
      return if recording && RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)

      head :forbidden
    end

    def location_request_actor
      if defined?(Current) && Current.respond_to?(:actor)
        actor = Current.actor.presence
        return actor if actor
      end

      current_user if respond_to?(:current_user, true)
    end

    def location_search_recording_for(actor)
      if respond_to?(:current_root_recording)
        root = current_root_recording
        return root if root && RecordingStudioAccessible.authorized?(actor: actor, recording: root, role: :view)
      end

      RecordingStudioAccessible.root_recordings_for(actor: actor, minimum_role: :view).first
    end

    def invoke_authenticate_callback(callback)
      if callback.arity == 1
        callback.call(self)
      else
        instance_exec(&callback)
      end
    end
  end
end
