# Recording Studio Location

`recording_studio_location` stores a physical place as a normal Recording Studio recordable.

- Gem: `recording_studio_location` (`RecordingStudioLocation`)
- Recordable: `RecordingStudio::Location::Location` (not a root)
- Capability: `:location`, opted in with `RecordingStudio::Capabilities::Location.to`
- Optional address fields, ISO `country_code`, and nullable latitude/longitude
- Helpers: `display_name`, `full_address`, `coordinates`, `resolved_icon`
- Optional `title`, `location_type`, and `icon`
- FlatPack form fields, search helper, and a read-only display partial
- Optional geocoder/search adapter (Google built-in, Fake for tests), `geocode!` / `reverse!`, plus `#search` / `#details`
- Gemspec: `add_dependency "recording_studio", "~> 4.2"`
- Dummy GitHub tags: Recording Studio `v4.3.0`, Accessible `v0.10.1`, Root Switchable `v0.5.1`, FlatPack `v0.1.213`

Installing the gem does not enable Location on every type. Enable `:location` on each parent that may contain a place.
