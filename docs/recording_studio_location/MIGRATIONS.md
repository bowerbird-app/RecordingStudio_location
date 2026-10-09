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
| `title` | Optional user label, added in 0.4.0 |
| `location_type` | Optional type key, added in 0.4.0 |
| `icon` | Optional FlatPack icon name, added in 0.4.0 |
| `name` | Optional venue or place name |
| `address_line_1`, `address_line_2` | Optional street lines |
| `locality`, `region`, `postal_code` | Optional |
| `country_code` | ISO 3166-1 alpha-2, two characters |
| `latitude` | Decimal, precision 10 scale 7 |
| `longitude` | Decimal, precision 11 scale 7 |

Indexes: `country_code`, `locality`, `name`. There is no PostGIS column. `title`, `location_type`, and `icon` are nullable so existing rows stay valid.

The table uses `gen_random_uuid()`. PostgreSQL needs `pgcrypto` (Recording Studio hosts already enable it).

`db/migrate/20261009000001_add_title_type_and_icon_to_recording_studio_locations.rb` adds the identity columns. Hosts that already installed the create table still run the migrations generator to copy this file.

## New engine migrations later

Add files under `db/migrate/` in this gem. Hosts run the migrations generator again. The generator stamps a new timestamp in the host `db/migrate/` and skips names that are already there.
