# frozen_string_literal: true

module RecordingStudioLocation
  # Loads the Location recordable and registers it with Recording Studio.
  module RecordableRegistration
    module_function

    def register!
      return unless defined?(RecordingStudio)

      recordable = RecordingStudio::Location::Location
      RecordingStudio.register_recordable_type(recordable.name)
      RecordingStudio.enable_capability(:location_lookup, on: recordable)
    end
  end
end
