# Changelog

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
