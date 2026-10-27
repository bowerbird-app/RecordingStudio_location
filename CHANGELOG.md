# Changelog

## [Unreleased]

## [0.8.1] - 2026-10-27

### Changed

- A selected place hides search and shows the summary. Address fields stay collapsed until Edit address or Add address manually, or until the record has errors. Picking a place fills the hidden inputs and does not open them. Clear location returns to search.

### Upgrade notes

- Hosts who copied the old partial should hide search when a place is selected and keep the address inputs in the DOM when collapsed. No migration. Rebuild Tailwind so `hidden` stays in the scan.

## [0.8.0] - 2026-10-27

### Changed

- Requires Recording Studio `>= 6.1.0` (dummy tag `v6.1.0`) and FlatPack `>= 0.1.315` (dummy ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56`, version `0.1.319`).
- `RecordingStudioLocation::Configuration#layout` defaults to nil. The setter accepts a value through `RecordingStudio::Layout.accept`. Engine controllers call `recording_studio_layout` and let a nil setting fall through to the host layout, then `recording_studio/default_layout`.
- Dummy pages set `content_for :title` and `:subtitle`. The default layout renders the only page `<h1>`. Back and close use `flat_pack_page_nav`. Sign out is a `register_page_nav` entry.
- Cards use `background`, `border`, and `shadow` instead of `style`.
- The location display prints the address without a card and does not print coordinates. The map sits in column 1 of a two-column grid. The page title carries the place name.
- Search address fields render inline in `recording_studio_location_search_fields`. The partial no longer uses `FlatPack::Modal`, so it works on a full page and inside a host modal. Add address manually (the button under search, and the no-results row) shows the fields and focuses the first input. Picking a place shows them too. Clear location hides them again.
- Removed unused copy keys `recording_studio.location.search.done` and `recording_studio.location.search.modal_title`.
- Dummy no longer ships `recording_studio/_default_layout_head`. That partial linked `flat_pack/application.css` again after Tailwind, so preflight zeroed form padding and radius. `rake test:dummy` rebuilds Tailwind after linking the installed Flatpack.

### Upgrade notes

- Bump to `0.8.0` with Recording Studio `>= 6.1.0` and FlatPack `>= 0.1.315`. No database migration.
- Remove `RecordingStudio::UsesDefaultLayout`, `recording_studio_page_nav`, and `layout "recording_studio/default_layout"`. Call `recording_studio_layout` and set `content_for :title`.
- Sibling gems that still declare `recording_studio < 5` need their requirement relaxed before Bundler resolves `6.1.0`. The dummy app does this in `test/support/widen_recording_studio_requirement.rb`.
- Dummy Root Switchable moves to `v0.11.0` and Metrics to `v0.6.1`. `v0.9.0` still calls removed Flatpack page-nav arguments. `v0.11.0` needs Metrics `>= 0.3.0`.
- Development Ruby pin is 3.3.13. GitHub's Ubuntu 26.04 image does not publish a Ruby 3.3.6 build.
- Drop host overrides of `recording_studio.location.search.done` and `search.modal_title`. If a host copied the old search partial, render the address fields inline instead of opening a modal. Rebuild Tailwind so `hidden` on those fields is included.
- If a host copied the dummy `recording_studio/_default_layout_head` partial, delete it. Flatpack's application CSS must stay before `tailwind.css`.

## [0.7.0] - 2026-10-14

### Added

- English fallback for shipped `recording_studio.location.*` keys when the active
  locale has no translation: nested gem keys go through `RecordingStudio.t` so
  missing keys resolve the loaded `:en` value (host English overrides included),
  then the caller's `default:`, then the gem-shipped English table registered at
  boot via `RecordingStudio::Translation.register_shipped_english`
- Behavioral coverage for fallback order, escaping parity vs view `t`, boot-loaded
  host override on a real page, deleted-key renders, drift guard against
  hand-copied English `default:`s, and multi-seed suite stability

### Changed

- `RecordingStudioLocation::Copy` and `recording_studio_location_t` route nested
  gem keys through `RecordingStudio.t` (legacy `recording_studio_location.*` host
  keys still win when present). Hand-copied English `default:`s that matched
  `en.yml` were removed from validation helpers.
- Requires RecordingStudio `~> 4.7` (dummy GitHub tag `v4.7.0`)
- Legacy `recording_studio_location.*` host keys stay on plain `I18n.t` with
  main's `default:` chain; only nested `recording_studio.location.*` gem keys
  go through `RecordingStudio.t`

### Upgrade notes

- Bump to `0.7.0` and RecordingStudio `~> 4.7`. No migration.
- Fallback comes from the loaded English, host overrides included.
- Missing `_html` key with a non-interpolating String caller `default:` stays
  unsafe like view `t`; interpolating or Array caller `default:` on a missing
  `_html` key is stricter than main/view `t` (args escaped, result html_safe).
  A plain default with no interpolation is returned as a plain (non-html_safe)
  String, so views will escape it.
- English hosts need no change. Hosts still override by defining the same nested
  keys in their own `config/locales`. Deprecated `recording_studio_location.*`
  host keys still win via `Copy` / `I18n.t`.

## [0.6.0] - 2026-10-12

### Added

- English Rails I18n keys for validation messages under `recording_studio.location.errors`
  (`location_type_not_in_list`, `icon_not_in_list`, `country_code_iso`, `must_be_a_number`)
- Host English override coverage: test-only fixture
  `test/dummy/test/locales/location_host_override.en.yml` plus render-level and
  `errors.details` asserts (English, French, and host override)
- Locale regression: every `lib/**/*.rb` file must not mention `i18n.load_path` /
  `I18n.load_path`
- Legacy-first `Copy.t` coverage for type labels, icon labels, and map titles
  (host `recording_studio_location.*` wins; nested gem English otherwise)

### Changed

- Identity and Location validation messages resolve through `Copy.t` with English
  `default:`. Inclusion and format validations keep main's symbol error types
  (`:inclusion`, `:invalid`) via `message:`. The coordinate "must be a number"
  check keeps a String error type and passes the translated string as the type
  (ActiveModel 8.1 ignores `message:` for Strings). In non-English locales,
  `errors.details` carries the translated string for that former String type.
- Public model return values stay main's literal English (`display_name` fallback
  `"Location"`, recordable declaration labels, config type labels as fallbacks).
  API JSON error tokens (`not_found`, `unavailable`) stay raw.

### Upgrade notes

- Bump to `0.6.0`. No migration.
- English hosts need no change. Copy new `recording_studio.location.errors.*` keys
  into host locale files when translating.
- Hosts override by defining the same nested keys in their own `config/locales`.
  Deprecated `recording_studio_location.*` host keys still win via `Copy`.
- When a former String-typed validation error is translated, `errors.details`
  carries the translated string in non-English locales (English remains
  byte-identical to main).

## [0.5.1] - 2026-10-09

### Fixed

- Stop appending the gem's locale files to `I18n.load_path` in an engine
  initializer. Rails engines already load `config/locales` automatically; the
  explicit append reloaded gem English after the host's locales on Rails 8.1,
  so host overrides under `recording_studio.location.*` lost. Host nested
  overrides win again; legacy `recording_studio_location.*` lookup is unchanged.

### Upgrade notes

- Bump to `0.5.1`. No migration. Prefer host overrides under
  `recording_studio.location.*` in `config/locales` (no need to touch
  `I18n.load_path`).

## [0.5.0] - 2026-10-09

### Added

- Nested English Rails I18n keys for gem interface copy under `recording_studio.location`
  in `config/locales/en.yml` (fields, search, map, location types, icons)
- `RecordingStudioLocation::Copy` (and view helper `recording_studio_location_t`) so
  a host-defined deprecated `recording_studio_location.*` key wins, otherwise the
  nested gem key is used
- Locale and copy tests for nested English and host legacy overrides

### Changed

- Gem views, identity type/icon labels, and map preview titles resolve through
  the copy helper (rendered English unchanged)
- Removed unused `search.no_results` and `search.results_count` keys
- Stopped shipping `config/locales/recording_studio_location.en.yml` (hosts may
  still define that namespace themselves)

### Upgrade notes

- No migration is required for English hosts that use the gem defaults.
- Prefer overrides under `recording_studio.location.*` in the host's
  `config/locales`.
- Deprecated: host overrides under `recording_studio_location.*` still work via
  the copy helper. The gem no longer ships English under that namespace, so a
  host must define any legacy keys it still wants.
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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_location/compare/v0.8.1...HEAD
[0.8.1]: https://github.com/bowerbird-app/RecordingStudio_location/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/bowerbird-app/RecordingStudio_location/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/bowerbird-app/RecordingStudio_location/compare/v0.6.1...v0.7.0
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_location/compare/v0.5.1...v0.6.0
