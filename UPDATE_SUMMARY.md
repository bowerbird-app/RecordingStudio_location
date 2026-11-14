# Recording Studio Location

`recording_studio_location` stores a physical place as a normal Recording Studio recordable.

- Gem: `recording_studio_location` (`RecordingStudioLocation`)
- Recordable: `RecordingStudio::Location::Location` (not a root)
- Capability: `:location`, opted in with `RecordingStudio::Capabilities::Location.to`
- Optional address fields, ISO `country_code`, and nullable latitude/longitude
- Helpers: `display_name`, `full_address`, `coordinates`, `resolved_icon`
- Optional `title`, `location_type`, and `icon`
- FlatPack form fields, a progressive search helper (summary when a place is selected, address fields on demand), and a read-only display partial
- Optional geocoder/search adapter (Google built-in, Fake for tests), `geocode!` / `reverse!`, plus `#search` / `#details`
- Gemspec: `add_dependency "recording_studio", ">= 6.1.0"` and `flat_pack >= 0.1.315`
- Dummy GitHub pins: Recording Studio `v6.14.0`, Accessible `v0.41.0`, Root Switchable `v0.15.0`, Metrics `v0.8.0`, Trashable `v0.15.0`, Cache `v0.6.3`, Recording Studio API `v0.23.3`, Admin `v2.13.1`, Logs `v0.7.5`, Moveable `v4.2.0`, Icons `v0.2.1`, FlatPack `0.1.374`
- Location is `0.10.0`

Installing the gem does not enable Location on every type. Enable `:location` on each parent that may contain a place.
