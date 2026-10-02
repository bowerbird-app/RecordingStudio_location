# frozen_string_literal: true

RecordingStudioLocation.configure do |config|
  # Reserved for a future geocoding adapter. This version stores the object and
  # does not call it, so address text is never sent to an external service.
  # config.geocoder = nil
end

# Enable Location on each host recordable that may contain a place.
# Do not list those parents inside the Location gem.
#
#   class Workspace < ApplicationRecord
#     recording_studio_recordable label: "Workspace", root: true
#     include RecordingStudio::Capabilities::Location.to
#   end
