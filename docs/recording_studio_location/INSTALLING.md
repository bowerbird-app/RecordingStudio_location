# Installing Location in a host

Add Location to a Recording Studio host. The public product notes live in the [README](../../README.md).

## Prerequisites

- Rails 8.1+
- PostgreSQL (UUID primary keys)
- `recording_studio ~> 4.2`
- FlatPack for the form and display partials

## Add the gem

```ruby
gem "recording_studio", "~> 4.2"
gem "recording_studio_location"
gem "flat_pack"
```

```bash
bundle install
bin/rails generate recording_studio_location:install
bin/rails generate recording_studio_location:migrations
bin/rails db:migrate
```

Keep `config.require_recordable_declarations = true`.

## What the install generator does

1. Mounts `RecordingStudioLocation::Engine` at `/recording_studio_location` (override with `--mount_path`).
2. Copies `config/initializers/recording_studio_location.rb`.
3. Optionally copies `config/recording_studio_location.yml`.
4. Adds Tailwind `@source` lines for Location views and FlatPack components when `app/assets/tailwind/application.css` exists.

Mount line:

```ruby
mount RecordingStudioLocation::Engine, at: "/recording_studio_location"
```

The engine root is a tiny home page. Host screens should render `recording_studio_location_fields` and `recording_studio_location_display` themselves.

## Enable it on a parent

Location is not a root. Register the type, then opt in `:location` on each recordable that may contain a place.

```ruby
class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", plural_label: "Workspaces", root: true

  include RecordingStudio::Capabilities::Location.to
end
```

Do not list host models such as Business or PressKit inside this gem.

## Tailwind

The installer looks for `@import "tailwindcss"` and injects sources similar to:

```css
@source "../../vendor/bundle/**/recording_studio_location/app/views/**/*.erb";
@source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";
```

Rebuild with `bin/rails tailwindcss:build`.

## After install

1. Review the initializer. `geocoder` is reserved and unused in this version.
2. Copy migrations and migrate.
3. Enable `:location` on the parents that should hold a place.
