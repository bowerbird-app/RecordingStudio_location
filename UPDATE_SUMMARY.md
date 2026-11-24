# Recording Studio Location

`recording_studio_location` stores a physical place as a normal Recording Studio recordable.

- Gem: `recording_studio_location` (`RecordingStudioLocation`)
- Recordable: `RecordingStudio::Location::Location` (not a root)
- Capability: `:location`, opted in with `RecordingStudio::Capabilities::Location.to`
- Optional address fields, `country_code` from the built-in country list, and nullable latitude/longitude
- Helpers: `display_name`, `full_address`, `coordinates`, `resolved_icon`
- Optional `title`, `location_type`, and `icon`
- FlatPack form fields, a progressive search helper (summary when a place is selected, address fields on demand), and a read-only display partial
- Optional geocoder/search adapter (Google built-in, Fake for tests), `geocode!` / `reverse!`, plus `#search` / `#details`
- Gemspec: `add_dependency "recording_studio", ">= 7.1", "< 8.0"` and `flat_pack >= 0.1.315`
- Dummy GitHub pins: Recording Studio `v7.8.0`, Accessible `v0.55.0`, Root Switchable `v0.16.1`, Metrics `v0.9.2`, Trashable `v1.2.3`, Cache `v0.7.1`, Recording Studio API `v1.19.0`, Admin `v2.19.1`, Logs `v0.8.2`, Moveable `v6.0.3`, Icons `v0.4.2`, FlatPack `0.2.0`
- Location is `0.15.0`

Installing the gem does not enable Location on every type. Enable `:location` on each parent that may contain a place.
