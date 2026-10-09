# frozen_string_literal: true

module RecordingStudioLocation
  module LocationsHelper
    LOCATION_FIELD_NAMES = %i[
      name
      address_line_1
      address_line_2
      locality
      region
      postal_code
      country_code
      latitude
      longitude
    ].freeze

    def recording_studio_location_fields(form, title: true, location_type: true, icon: true)
      render partial: "recording_studio_location/locations/fields", locals: {
        form: form,
        show_title: title,
        show_location_type: location_type,
        show_icon: icon
      }
    end

    def recording_studio_location_search_fields(form, lookup: nil, title: true, location_type: true, icon: true)
      unless RecordingStudioLocation::Geocoder.searchable?
        return recording_studio_location_fields(form, title: title, location_type: location_type, icon: icon)
      end

      render partial: "recording_studio_location/locations/search_fields",
             locals: search_fields_locals(form, lookup, title, location_type, icon)
    end

    def recording_studio_location_display(location, map: false)
      render partial: "recording_studio_location/locations/display", locals: {
        location: location,
        show_map: map
      }
    end

    def recording_studio_location_map(latitude: nil, longitude: nil, live: false)
      preview = RecordingStudioLocation::Map.preview(latitude: latitude, longitude: longitude)
      return if preview.nil?
      return if !live && !preview.visible?

      render partial: "recording_studio_location/locations/map", locals: {
        preview: preview,
        live: live
      }
    end

    def recording_studio_location_filled?(location)
      return false unless location

      LOCATION_FIELD_NAMES.any? { |attribute| location.public_send(attribute).present? }
    end

    # Host legacy `recording_studio_location.*` wins; else nested gem English.
    def recording_studio_location_t(key, **)
      RecordingStudioLocation::Copy.t(key, **)
    end

    private

    def search_fields_locals(form, lookup, title, location_type, icon)
      {
        form: form,
        lookup_depth: RecordingStudioLocation::Geocoder::LookupDepth.normalize(
          lookup.presence || RecordingStudioLocation.configuration.lookup_depth
        ),
        show_title: title,
        show_location_type: location_type,
        show_icon: icon
      }
    end
  end
end
