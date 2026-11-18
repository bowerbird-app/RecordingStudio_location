# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `>= 7.1, < 8.0` (gemspec floor; dummy GitHub tag `v7.7.1`)
- Accessible dummy tag `v0.54.0`, Root Switchable dummy tag `v0.16.0`, Metrics `v0.9.2`, Trashable `v1.2.0`, Cache `v0.7.0`
- Recording Studio API dummy tag `v1.15.0` when that gem is loaded (`>= 1.1, < 2.0`; not a gemspec dependency), Admin `v2.19.0`, Logs `v0.8.1`, Moveable `v6.0.1`, Icons `v0.4.2`
- FlatPack `>= 0.1.315` (dummy GitHub tag `v0.1.378`)
- Public RubyGems and GitHub access for dependency installation

## Upgrades

- 0.13.0 adds `config.register_api_endpoints_on`. `:all` (the default) registers `location_geocode` and `location_reverse` on every Recording Studio API. A list of API names registers them only on those APIs. `false` or `[]` registers neither. No Location migration. Names, paths, inputs, and authorization are unchanged.
- 0.12.5 moves development and dummy pins to Recording Studio `v7.7.1` and FlatPack `v0.1.378`. Dummy Accessible is `v0.54.0`, API `v1.15.0`, Admin `v2.19.0`, Logs `v0.8.1`, Metrics `v0.9.2`, Moveable `v6.0.1`, Icons `v0.4.2`, and Trashable `v1.2.0`. Cache `v0.7.0` and Root Switchable `v0.16.0` stay. No Location migration. The dummy copies Recording Studio API `20261117000024_add_owner_to_recording_studio_api_api_clients` so API clients can store an owner. Hosts that mount Recording Studio API 1.12 or newer need `config/recording_studio_api.yml` (`shared: {}` is enough to boot). Hosts on API 1.15 copy that owner migration.
- 0.12.4 returns `latitude` and `longitude` in API and MCP JSON as numbers, or null when absent. Hosts that read these two fields as strings now get numbers. No migration.
- 0.12.3 sets the OpenAPI tag `Location` on `location_geocode` and `location_reverse` and shortens their summaries. No migration.
- 0.12.2 rewrites the `location_geocode` and `location_reverse` tool descriptions. No migration.
- 0.12.0 requires Recording Studio `>= 7.1, < 8.0`. No Location migration. Copy `20261116120000_add_recording_studio_events_timeline_index` on Recording Studio 7.2 or newer. When Recording Studio API is loaded, require `>= 1.1, < 2.0`. `location_geocode` and `location_reverse` register a Location `recordable_type` and `required_role: :edit`.
- 0.11.0 requires Recording Studio `>= 7.0, < 8.0`. No Location migration. `root_recording_for` only finds a root. Seeds and setup that created a root by looking it up call `create_root_recording!`. `authorize_write` must allow that create when `root_recording` is nil.
- Dummy apps on Recording Studio 6.9+ copy `20261114090000_add_root_recording_id_to_recording_studio_events` before writing events. Location itself has no new migration.
- 0.10.0 adds Recording Studio API lookups `location_geocode` and `location_reverse`. Place search and place details stay off that API. No Location migration. Copy API and Logs migrations when mounting API in a host or dummy.
- 0.9.0 routes search, dummy locations, and the recordings tree through Accessible. No Location migration. Copy Accessible access-request migrations when bumping the dummy Accessible pin.
- 0.8.3 is a lockfile security bump. No migration.
- 0.8.2 is docs hygiene. No migration.
- 0.8.1 changes search disclosure and needs no migration.

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
