# Location migrations

The host database owns `recording_studio_locations`. Copy the engine migration, then migrate.

```bash
bin/rails generate recording_studio_location:migrations
bin/rails db:migrate
```

`--skip-existing` is the default. Pass `--skip-existing=false` only when you mean to copy a second copy.

## Table

`db/migrate/20261002000001_create_recording_studio_locations.rb` creates a UUID table:

| Column | Notes |
| --- | --- |
| `name` | Optional label |
| `address_line_1`, `address_line_2` | Optional street lines |
| `locality`, `region`, `postal_code` | Optional |
| `country_code` | ISO 3166-1 alpha-2, two characters |
| `latitude` | Decimal, precision 10 scale 7 |
| `longitude` | Decimal, precision 11 scale 7 |

Indexes: `country_code`, `locality`, `name`. There is no PostGIS column.

The table uses `gen_random_uuid()`. PostgreSQL needs `pgcrypto` (Recording Studio hosts already enable it).

## New engine migrations later

Add files under `db/migrate/` in this gem. Hosts run the migrations generator again. The generator stamps a new timestamp in the host `db/migrate/` and skips names that are already there.
