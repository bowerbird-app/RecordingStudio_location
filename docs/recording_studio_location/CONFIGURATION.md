# Location configuration

Location has a small host config. Address fields live on `RecordingStudio::Location::Location`, not in this hash.

## Initializer

`bin/rails generate recording_studio_location:install` copies `config/initializers/recording_studio_location.rb`:

```ruby
RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
end
```

`from_rails_credentials` builds a Google adapter when Rails credentials (or ENV) include both `provider` and `api_key`. Either missing value leaves `geocoder` nil. Saving a location never geocodes by itself.

`RecordingStudio::Location.geocoder =` writes the same slot. Assign `RecordingStudioLocation::Geocoder::Fake` in tests.

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

Do not commit the key. Do not put it in `config/recording_studio_location.yml`.

## YAML

Optional `config/recording_studio_location.yml`:

```yaml
development:
  geocoder:

production:
  geocoder:
```

The engine loads it with `Rails.application.config_for(:recording_studio_location)` when the file exists. Unknown keys are ignored. `geocoder` from YAML is not a live adapter object.

You can also set `config.x.recording_studio_location` in Rails config. The initializer wins last.

## Read it back

```ruby
RecordingStudioLocation.configuration.geocoder
RecordingStudioLocation.configuration.to_h
```

`to_h` includes `geocoder` and a count of registered hooks. It is for inspection, not persistence.

## Capability is not configuration

Installing the gem does not let every recordable contain a Location. Enable `:location` on each parent:

```ruby
include RecordingStudio::Capabilities::Location.to
```

## Files

| Path | Role |
| --- | --- |
| `lib/recording_studio_location/configuration.rb` | Defaults |
| `lib/recording_studio_location/geocoder.rb` | Factory and credentials |
| `lib/recording_studio_location/engine.rb` | Loads YAML, `config.x`, then initializer |
| `lib/generators/recording_studio_location/install/templates/` | Initializer and YAML templates |
