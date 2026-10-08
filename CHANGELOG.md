# Changelog

## [0.3.0] - 2026-10-08

### Added

- `recording_studio_location_search_fields(form)` — search-first editor. Pick a result to fill structured fields. Manual entry opens a FlatPack modal. Existing `recording_studio_location_fields(form)` is unchanged.
- Provider adapter surface: `#search`, `#details`, `#attribution`, `#capabilities`, plus existing `#geocode` / `#reverse`. Register extra providers with `Geocoder.register`.
- Google adapter: Places Autocomplete while typing, Place Details on pick (`lookup_depth: :full`), or Geocoding-by-id (`:address`). Attribution is provider-driven.
- `Geocoder::Fake#stub_search` / `#stub_details` and `Fake.demo` for dummy/dev without a live key.
- Engine JSON endpoints `GET /searches` and `GET /places`, authenticated (`config.authenticate` or Devise `authenticate_user!`, else 401). API keys never reach the browser.
- Stimulus controller `recording-studio-location--place-search`. Install generator pins it in `config/importmap.rb`.
- English locale keys under `recording_studio_location.*`.

### Upgrade notes

- Bump to `0.3.0`. No database migration.
- Enable the Places API (legacy) on the same key if you want search. Geocoding-only keys keep `geocode!` / `reverse!` working; the search helper falls back to the full form when the adapter cannot search.
- Pin Location Stimulus controllers (the install generator does this). Rebuild Tailwind so new view classes are included.
- Switch a host form to `recording_studio_location_search_fields(form)` when you want search. Presskits should do that in a follow-up.
- Optional `config.lookup_depth = :full` (default) or `:address`. Optional `config.authenticate` proc if the host is not Devise.
- Saving still never geocodes. A pick overwrites structured fields, including `name` when the lookup returns one. Users can edit or clear anything afterwards.

## [0.2.0] - 2026-10-06

### Added

- Explicit `Location#geocode!` (address → coordinates) and `Location#reverse!` (coordinates → blank address fields).
- Provider factory `RecordingStudioLocation::Geocoder.build` with a Google Geocoding API adapter.
- `RecordingStudioLocation::Geocoder::Fake` for tests. CI does not call a live provider.
- Generated initializer that sets `config.geocoder` from Rails credentials (or ENV) when both `provider` and `api_key` are present.

### Upgrade notes

- Bump to `0.2.0`. No database migration.
- Geocoding stays off until the host sets credentials. Existing apps that leave the initializer unset keep the old inert behavior.
- Replace the reserved `config.geocoder = nil` comment with `config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials`.
- Store secrets in Rails credentials, not YAML:

  ```yaml
  recording_studio_location:
    geocoder:
      provider: google
      api_key: "..."
  ```

  Optional ENV overrides: `RECORDING_STUDIO_LOCATION_GEOCODER_PROVIDER` and `RECORDING_STUDIO_LOCATION_GEOCODER_API_KEY`.
- Call `geocode!` / `reverse!` yourself inside `record` or `revise`. Nothing runs on save.
- Forward geocoding writes latitude and longitude only. It does not rewrite address fields.
- Reverse geocoding fills blank address fields. Pass `force: true` to overwrite fields that already have text.
- Missing adapter, blank query, empty provider result, and HTTP/provider errors raise (`RecordingStudioLocation::Geocoder::Missing`, `QueryError`, `NotFound`, `RequestError`).

## [0.1.0] - 2026-10-02

### Added

- `RecordingStudio::Location::Location`, a non-root Recording Studio recordable for a physical place.
- Capability `:location` so a host chooses which recordables may contain a location.
- Optional address fields, ISO `country_code`, and nullable latitude/longitude.
- `display_name`, `full_address`, and `coordinates`.
- FlatPack form fields and a read-only display partial.
- Install and migrations generators for `recording_studio_locations`.
- A reserved `RecordingStudio::Location.geocoder` setting that is not called.

### Changed

- Dummy and root GitHub tags pin Recording Studio `v4.2.2`.
- Dummy credentials use the shared Recording Studio development master key.

Maps, geocoding, spatial search, and domain-specific parent models are intentionally absent.
