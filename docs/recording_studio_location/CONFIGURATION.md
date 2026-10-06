# Location configuration

Location has a small host config. Address fields live on `RecordingStudio::Location::Location`, not in this hash.

## Initializer

`bin/rails generate recording_studio_location:install` copies `config/initializers/recording_studio_location.rb`:

```ruby
RecordingStudioLocation.configure do |config|
  # Reserved for a future geocoding adapter. This version stores the object and
  # does not call it, so address text is never sent to an external service.
  # config.geocoder = nil
end
```

`RecordingStudio::Location.geocoder =` writes the same slot.

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
| `lib/recording_studio_location/engine.rb` | Loads YAML, `config.x`, then initializer |
| `lib/generators/recording_studio_location/install/templates/` | Initializer and YAML templates |
