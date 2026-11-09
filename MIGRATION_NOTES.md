# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio `>= 6.1.0` (gemspec floor; dummy GitHub tag `v6.1.0`)
- Accessible dummy tag `v0.24.2`, Root Switchable dummy tag `v0.11.0`, Metrics `v0.7.3`, Trashable `v0.12.3`, Cache `v0.6.3`
- FlatPack `>= 0.1.315` (dummy git ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56`, version `0.1.319`)
- Public RubyGems and GitHub access for dependency installation

## Upgrades

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
