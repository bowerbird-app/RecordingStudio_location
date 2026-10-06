# Location hooks

Location does not ship its own hooks class. `RecordingStudioLocation.configuration.hooks` is a `RecordingStudio::Hooks` instance.

The engine runs:

- `before_initialize`
- `on_configuration` (after YAML and `config.x` merge)
- `after_initialize`

It also applies `extend_model` and `extend_controller` registrations during `to_prepare`.

```ruby
RecordingStudioLocation.configure do |config|
  config.hooks.after_initialize do
    Rails.logger.info "Location engine ready"
  end
end
```

Service hooks (`before_service`, `after_service`, `around_service`) exist because the shared Hooks object supports them. This gem has no service objects that fire them.

Prefer Recording Studio's `record` / `revise` / `log_event!` over inventing a parallel write path in a hook.
