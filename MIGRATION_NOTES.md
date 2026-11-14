# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `>= 6.1.0` (gemspec floor; dummy GitHub tag `v6.10.0`)
- Accessible dummy tag `v0.37.0`, Root Switchable dummy tag `v0.15.0`, Metrics `v0.8.0`, Trashable `v0.14.1`, Cache `v0.6.3`
- Recording Studio API dummy tag `v0.23.1`, Admin `v2.13.0`, Logs `v0.7.4`, Moveable `v4.1.1`, Icons `v0.2.1`
- FlatPack `>= 0.1.315` (dummy GitHub tag `v0.1.366`)
- Public RubyGems and GitHub access for dependency installation

## Upgrades

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
