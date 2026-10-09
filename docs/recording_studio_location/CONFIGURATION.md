# Location configuration

Location has a small host config. Address fields live on `RecordingStudio::Location::Location`, not in this hash.

## Initializer

`bin/rails generate recording_studio_location:install` copies `config/initializers/recording_studio_location.rb`:

```ruby
RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
  config.map = RecordingStudioLocation::Map.from_rails_credentials
  config.lookup_depth = :full
  config.icon_mode = :type
  # config.authenticate = ->(controller) { controller.authenticate_user! }
end
```

`from_rails_credentials` builds a registered adapter when Rails credentials (or ENV) include both `provider` and `api_key`. Either missing value leaves `geocoder` nil. Saving a location never geocodes by itself. The search helper then renders the full form.

`RecordingStudio::Location.geocoder =` writes the same slot. Assign `RecordingStudioLocation::Geocoder::Fake` in tests.

### map

A separate adapter from geocoding. The search helper shows a pin under the Location field only when both coordinates are present. `recording_studio_location_display(location, map: true)` is the same preview on read-only views and is off by default.

| Provider | Config | Key |
| --- | --- | --- |
| Google Maps Embed | `provider: google` | `browser_api_key` — HTTP-referrer restricted browser key. Never the Geocoding server key. Enable Maps Embed API. |
| OpenStreetMap embed | `provider: open_street_map` (aliases `osm`, `openstreetmap`) | None |

```ruby
config.map = RecordingStudioLocation::Map.from_rails_credentials
config.map = RecordingStudioLocation::Map.build(provider: "open_street_map")
```

Env: `RECORDING_STUDIO_LOCATION_MAP_PROVIDER`, `RECORDING_STUDIO_LOCATION_MAP_BROWSER_API_KEY`. Unset `config.map` shows no map and makes no map request.

The UI only uses `#preview`, which returns a `Map::Preview` (`url`, `url_template`, `title`). Register others with `Map.register`.

### lookup_depth

| Value | On pick |
| --- | --- |
| `:full` (default) | Venue name + address + coordinates |
| `:address` | Address + coordinates, no venue name |

Override one form: `recording_studio_location_search_fields(form, lookup: :address)`.

### title, type, and icon

A location can carry a user title, a host type, and an icon. `name` stays the venue the search fills.

| Setting | Default | Notes |
| --- | --- | --- |
| `location_types` | `office`, `home`, `venue`, `other` | Hash of `{ label:, icon: }`. Keys are stored on the row. Labels use i18n `recording_studio_location.location_types.*`; `label` is the fallback for custom keys. Default icons are real FlatPack names. |
| `icon_mode` | `:type` | `:type` — icon from the type, no picker, stored `icon` stays blank. `:choose` — user picks from `allowed_icons` with the same RadioGroup; picking a type checks that type's icon radio. `:none` — no icon in the form or display. |
| `allowed_icons` | `home building-office map-pin star briefcase` | FlatPack icon names. Used in `:choose` mode and as the inclusion list for stored icons. |
| `default_icon` | `map-pin` | Last fallback for `resolved_icon`. |

`Location#resolved_icon` is stored icon → type icon → `default_icon`. A type or icon later dropped from config is skipped, not an error.

Form helpers accept `title:`, `location_type:`, and `icon:` (all default true) to hide those fields. Type and icon use FlatPack RadioGroup `variant: :inline` (icon + label buttons, real radios). The search helper's manual-address modal is address-only.

Use `RecordingStudio::Location.permitted_attributes` and `location.api_payload` on host forms, APIs, and MCP serializers.

### authenticate

Search endpoints require a logged-in user. Set `config.authenticate` to a proc if the host is not Devise. Default is `authenticate_user!` when that method exists, otherwise `401`.

## Credentials

On the installing app:

```yaml
recording_studio_location:
  geocoder:
    provider: google
    api_key: "SERVER_KEY"
  map:
    provider: google
    browser_api_key: "BROWSER_KEY"
```

Optional ENV overrides, which win when set:

- `RECORDING_STUDIO_LOCATION_GEOCODER_PROVIDER`
- `RECORDING_STUDIO_LOCATION_GEOCODER_API_KEY`
- `RECORDING_STUDIO_LOCATION_MAP_PROVIDER`
- `RECORDING_STUDIO_LOCATION_MAP_BROWSER_API_KEY`

Do not commit the key. Do not put it in `config/recording_studio_location.yml`. For Google search, enable Places API (legacy) as well as Geocoding on that key.

## YAML

Optional `config/recording_studio_location.yml`:

```yaml
development:
  lookup_depth: full
  icon_mode: type
  default_icon: map-pin
  geocoder:
  map:

production:
  lookup_depth: full
  icon_mode: type
  default_icon: map-pin
  geocoder:
  map:
```

The engine loads it with `Rails.application.config_for(:recording_studio_location)` when the file exists. Unknown keys are ignored. `geocoder` and `map` from YAML are not live adapter objects.

You can also set `config.x.recording_studio_location` in Rails config. The initializer wins last.

## Adapters

The UI and engine endpoints only call the geocoder adapter interface: `#search`, `#details`, `#geocode`, `#reverse`, `#attribution`, `#capabilities`. Google is registered as `"google"`. Register others with `RecordingStudioLocation::Geocoder.register("name", Klass)` or assign an instance to `config.geocoder`. Map adapters are a second registry (`config.map`).

`#search` must return an array (empty is fine) and must not raise `NotFound`. `#details` receives a candidate `id` and `depth:`. Attribution text is shown under results when present.

## Read it back

```ruby
RecordingStudioLocation.configuration.geocoder
RecordingStudioLocation.configuration.map
RecordingStudioLocation.configuration.lookup_depth
RecordingStudioLocation.configuration.icon_mode
RecordingStudioLocation.configuration.location_types
RecordingStudioLocation.configuration.to_h
```

`to_h` includes `geocoder`, `map`, `authenticate`, `lookup_depth`, identity settings, and a count of registered hooks. It is for inspection, not persistence.

## Capability is not configuration

Installing the gem does not let every recordable contain a Location. Enable `:location` on each parent:

```ruby
include RecordingStudio::Capabilities::Location.to
```

## Files

| Path | Role |
| --- | --- |
| `lib/recording_studio_location/configuration.rb` | Defaults |
| `lib/recording_studio_location/geocoder.rb` | Registry, factory, credentials |
| `lib/recording_studio_location/map.rb` | Map registry, factory, credentials |
| `lib/recording_studio_location/engine.rb` | Loads YAML, `config.x`, then initializer |
| `lib/generators/recording_studio_location/install/templates/` | Initializer and YAML templates |
