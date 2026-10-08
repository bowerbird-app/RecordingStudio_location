# frozen_string_literal: true

RecordingStudioLocation.configure do |config|
  # Builds a registered adapter when Rails credentials (or ENV) supply provider + api_key.
  # Dummy uses a local Fake when no key is present so the search helper can be demonstrated.
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
  config.geocoder ||= RecordingStudioLocation::Geocoder::Fake.demo if Rails.env.local?
  config.map = RecordingStudioLocation::Map.from_rails_credentials
  config.map ||= RecordingStudioLocation::Map.build(provider: "open_street_map") if Rails.env.local?
  config.lookup_depth = :full
end
