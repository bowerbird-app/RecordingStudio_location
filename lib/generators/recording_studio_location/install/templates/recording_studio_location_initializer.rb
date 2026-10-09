# frozen_string_literal: true

RecordingStudioLocation.configure do |config|
  # Builds a registered adapter (google) when Rails credentials (or ENV) supply
  # provider + api_key. Unset credentials keep this nil. Saving a location never
  # contacts a network service. Search helpers fall back to the full form when
  # the adapter is missing or does not support search.
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials

  # Optional map pin under the search field. Distinct from geocoder: Google
  # Embed needs a referrer-restricted browser key (never the server geocoding
  # key). OpenStreetMap embed needs no key. Unset shows no map.
  # config.map = RecordingStudioLocation::Map.from_rails_credentials
  # config.map = RecordingStudioLocation::Map.build(provider: "open_street_map")

  # :full (default) loads venue name + address + coordinates on pick.
  # :address is a cheaper address-only lookup (no venue name).
  # Override per form with recording_studio_location_search_fields(form, lookup: :address).
  config.lookup_depth = :full

  # Optional. Proc receives the engine controller. Default is Devise
  # authenticate_user! when present, otherwise 401.
  # config.authenticate = ->(controller) { controller.authenticate_user! }
end

# Enable Location on each host recordable that may contain a place.
# Do not list those parents inside the Location gem.
#
#   class Workspace < ApplicationRecord
#     recording_studio_recordable label: "Workspace", root: true
#     include RecordingStudio::Capabilities::Location.to
#   end
