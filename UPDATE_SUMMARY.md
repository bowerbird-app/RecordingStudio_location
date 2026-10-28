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
- Dummy GitHub pins: Recording Studio `v6.1.0`, Accessible `v0.18.0`, Root Switchable `v0.11.0`, Metrics `v0.6.1`, Trashable `v0.11.0`, Cache `v0.5.0`, FlatPack `0.1.319`
- Location is `0.8.2`

Installing the gem does not enable Location on every type. Enable `:location` on each parent that may contain a place.
