# Changelog

## [0.5.0] - 2026-10-09

### Added

- Nested English Rails I18n keys for gem interface copy under `recording_studio.location`
  in `config/locales/en.yml` (fields, search, map, location types, icons)
- `test/locales_test.rb` covering nested key resolution and English-only locale files

### Changed

- Gem views, identity type/icon labels, and map preview titles resolve through
  `t("recording_studio.location.*")` (rendered English unchanged)

### Upgrade notes

- No migration or host code change is required for English.
- Legacy top-level keys in `config/locales/recording_studio_location.en.yml`
  (`recording_studio_location.*`) still ship so existing host overrides keep
  resolving. New overrides should use `recording_studio.location.*`.
- There is no dependency on `recording_studio_internationalization`.

## [0.4.0] - 2026-10-09

### Added

- `title`, `location_type`, and `icon` columns on `recording_studio_locations`. All nullable, so existing rows stay valid. `name` remains the venue the search fills.
- Host config: `location_types`, `icon_mode` (`:type` default, `:choose`, `:none`), `allowed_icons`, and `default_icon`. Type labels use i18n (`recording_studio_location.location_types.*`).
- `Location#resolved_icon` — stored icon, then the type's icon, then `default_icon`. Removed types and icons do not raise.
- Title (FlatPack TextInput) and Type (FlatPack RadioGroup `variant: :inline`, icon + label) on `recording_studio_location_fields` and `recording_studio_location_search_fields`, above the venue search/address fields. Opt out with `title:`, `location_type:`, and `icon:`.
- Icon picker in `:choose` mode uses the same RadioGroup. Picking a type checks that type's icon radio. Real radio inputs stay in the tab order.
- Display shows the resolved icon and title, then venue name and address. Missing title, type, or icon is fine.
- `RecordingStudio::Location.permitted_attributes` and `Location#api_payload` for strong params, duplication, API, and MCP serializers.

### Upgrade notes

- Bump to `0.4.0`.
- Bump FlatPack to `>= 0.1.212` (visual RadioGroup). Dummy pins `v0.1.213`. Rebuild Tailwind so the new radio utilities are generated.
- Copy and run the new migration:

  ```bash
  bin/rails generate recording_studio_location:migrations
  bin/rails db:migrate
  ```

- Existing locations keep working with blank title, type, and icon.
- Defaults: types `office` / `home` / `venue` / `other`, `icon_mode: :type`, allowed icons `home building-office map-pin star briefcase`, `default_icon: "map-pin"`.
- In `:type` mode the gem does not store `icon`; display resolves it. In `:choose` mode the picked icon is stored. In `:none` mode the form and display omit the icon.
- Permit `:title`, `:location_type`, and `:icon` on host forms and APIs, or use `RecordingStudio::Location.permitted_attributes`.
- Rebuild Tailwind so the new view classes are included.

## [0.3.0] - 2026-10-08

### Added

- `recording_studio_location_search_fields(form)` — search-first editor labelled Location. The field uses FlatPack Search chrome (leading magnifying-glass, search tokens, no chevron). Pick a result to fill structured fields; the search field then shows the place name. No results offers Add address manually, which opens a FlatPack modal. A picked or saved place shows a summary with a Clear location control (X) instead of an edit action. Existing `recording_studio_location_fields(form)` is unchanged. The dropdown uses FlatPack Combobox listbox classes and tokens.
- Provider adapter surface: `#search`, `#details`, `#attribution`, `#capabilities`, plus existing `#geocode` / `#reverse`. Register extra providers with `Geocoder.register`.
- Google adapter: Places Autocomplete while typing, Place Details on pick (`lookup_depth: :full`), or Geocoding-by-id (`:address`). Attribution is provider-driven.
- `Geocoder::Fake#stub_search` / `#stub_details` and `Fake.demo` for dummy/dev without a live key.
- Engine JSON endpoints `GET /searches` and `GET /places`, authenticated (`config.authenticate` or Devise `authenticate_user!`, else 401). API keys never reach the browser.
- Stimulus controller `recording-studio-location--place-search`. Install generator pins it in `config/importmap.rb`.
- Optional map pin under the search field via `config.map`. Google Maps Embed (referrer-restricted browser key) and keyless OpenStreetMap embed are built in. No adapter means no map and no network request. `recording_studio_location_display(location, map: true)` is off by default.
- English locale keys under `recording_studio_location.*`.

### Upgrade notes

- Bump to `0.3.0`. No database migration.
- Enable the Places API (legacy) on the same key if you want search. Geocoding-only keys keep `geocode!` / `reverse!` working; the search helper falls back to the full form when the adapter cannot search.
- Pin Location Stimulus controllers (the install generator does this). Rebuild Tailwind so new view classes are included.
- Switch a host form to `recording_studio_location_search_fields(form)` when you want search. Presskits should do that in a follow-up.
- Optional `config.lookup_depth = :full` (default) or `:address`. Optional `config.authenticate` proc if the host is not Devise.
- Optional `config.map` for a pin preview. Google Embed needs `recording_studio_location.map.browser_api_key` (HTTP-referrer restricted, never the geocoding server key) or use `Map.build(provider: "open_street_map")`. Unset shows nothing.
- Saving still never geocodes. A pick overwrites structured fields, including `name` when the lookup returns one. Clear location wipes the selection (all fields, summary, map, and the search text) and returns focus to search. Manual typing stays on Add address manually in the no-results dropdown. The map only loads after the user picks or types both coordinates.

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
