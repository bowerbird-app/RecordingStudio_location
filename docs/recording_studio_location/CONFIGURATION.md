# Location configuration

Location has a small host config. Address fields live on `RecordingStudio::Location::Location`, not in this hash.

## Initializer

`bin/rails generate recording_studio_location:install` copies `config/initializers/recording_studio_location.rb`:

```ruby
RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
  config.lookup_depth = :full
  # config.authenticate = ->(controller) { controller.authenticate_user! }
end
```

`from_rails_credentials` builds a registered adapter when Rails credentials (or ENV) include both `provider` and `api_key`. Either missing value leaves `geocoder` nil. Saving a location never geocodes by itself. The search helper then renders the full form.

`RecordingStudio::Location.geocoder =` writes the same slot. Assign `RecordingStudioLocation::Geocoder::Fake` in tests.

### lookup_depth

| Value | On pick |
| --- | --- |
| `:full` (default) | Venue name + address + coordinates |
| `:address` | Address + coordinates, no venue name |

Override one form: `recording_studio_location_search_fields(form, lookup: :address)`.

### authenticate

Search endpoints require a logged-in user. Set `config.authenticate` to a proc if the host is not Devise. Default is `authenticate_user!` when that method exists, otherwise `401`.

## Credentials

On the installing app:

```yaml
recording_studio_location:
  geocoder:
    provider: google
    api_key: "..."
```

Optional ENV overrides, which win when set:

- `RECORDING_STUDIO_LOCATION_GEOCODER_PROVIDER`
- `RECORDING_STUDIO_LOCATION_GEOCODER_API_KEY`

Do not commit the key. Do not put it in `config/recording_studio_location.yml`. For Google search, enable Places API (legacy) as well as Geocoding on that key.

## YAML

Optional `config/recording_studio_location.yml`:

```yaml
development:
  lookup_depth: full
  geocoder:

production:
  lookup_depth: full
  geocoder:
```

The engine loads it with `Rails.application.config_for(:recording_studio_location)` when the file exists. Unknown keys are ignored. `geocoder` from YAML is not a live adapter object.

You can also set `config.x.recording_studio_location` in Rails config. The initializer wins last.

## Adapters

The UI and engine endpoints only call the adapter interface: `#search`, `#details`, `#geocode`, `#reverse`, `#attribution`, `#capabilities`. Google is registered as `"google"`. Register others with `RecordingStudioLocation::Geocoder.register("name", Klass)` or assign an instance to `config.geocoder`.

`#search` must return an array (empty is fine) and must not raise `NotFound`. `#details` receives a candidate `id` and `depth:`. Attribution text is shown under results when present.

## Read it back

```ruby
RecordingStudioLocation.configuration.geocoder
RecordingStudioLocation.configuration.lookup_depth
RecordingStudioLocation.configuration.to_h
```

`to_h` includes `geocoder`, `authenticate`, `lookup_depth`, and a count of registered hooks. It is for inspection, not persistence.

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
| `lib/recording_studio_location/engine.rb` | Loads YAML, `config.x`, then initializer |
| `lib/generators/recording_studio_location/install/templates/` | Initializer and YAML templates |
