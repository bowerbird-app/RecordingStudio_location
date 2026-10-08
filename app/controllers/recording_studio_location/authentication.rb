# frozen_string_literal: true

module RecordingStudioLocation
  module Authentication
    extend ActiveSupport::Concern

    included do
      include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)
    end

    private

    def authenticate_location_request!
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

    def invoke_authenticate_callback(callback)
      if callback.arity == 1
        callback.call(self)
      else
        instance_exec(&callback)
      end
    end
  end
end
