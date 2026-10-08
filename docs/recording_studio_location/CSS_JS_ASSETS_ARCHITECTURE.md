# Location assets

Location ships FlatPack ERB partials and a Stimulus controller for place search. It does not ship a compiled CSS bundle or a mapping SDK.

- Form: `app/views/recording_studio_location/locations/_fields.html.erb`
- Search: `app/views/recording_studio_location/locations/_search_fields.html.erb`
- Display: `app/views/recording_studio_location/locations/_display.html.erb`
- Stimulus: `app/javascript/recording_studio_location/controllers/place_search_controller.js`

Helpers `recording_studio_location_fields`, `recording_studio_location_search_fields`, and `recording_studio_location_display` include those partials from the host.

## Importmap

The install generator appends:

```ruby
pin_all_from RecordingStudioLocation::Engine.root.join("app/javascript/recording_studio_location/controllers"), under: "controllers/recording_studio_location", to: "recording_studio_location/controllers"
```

The engine adds `app/javascript` to `config.assets.paths`. Dummy `config/importmap.rb` has the same pin. The controller identifier is `recording-studio-location--place-search`.

Host apps already lazy-load `controllers` the way they load FlatPack.

## Tailwind

The host Tailwind build must scan the gem views and FlatPack components. The install generator adds `@source` lines to `app/assets/tailwind/application.css` when that file exists.

Dummy app sources live in `test/dummy/app/assets/tailwind/application.css`. After view markup changes:

```bash
cd test/dummy
bin/rails tailwindcss:build
```

Missing styles usually mean the `@source` paths did not match the installed gem path, or the dummy CSS was not rebuilt.

Location does not embed maps or load a mapping JavaScript SDK. Place search calls engine JSON endpoints, not a provider from the browser.
