# frozen_string_literal: true

module RecordingStudioLocation
  module LocationsHelper
    def recording_studio_location_fields(form)
      render partial: "recording_studio_location/locations/fields", locals: { form: form }
    end

    def recording_studio_location_display(location)
      render partial: "recording_studio_location/locations/display", locals: { location: location }
    end
  end
end
