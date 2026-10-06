# Location assets

Location ships FlatPack ERB partials, not a compiled CSS or JS bundle.

- Form: `app/views/recording_studio_location/locations/_fields.html.erb`
- Display: `app/views/recording_studio_location/locations/_display.html.erb`

Helpers `recording_studio_location_fields` and `recording_studio_location_display` include those partials from the host.

## Tailwind

The host Tailwind build must scan the gem views and FlatPack components. The install generator adds `@source` lines to `app/assets/tailwind/application.css` when that file exists.

Dummy app sources live in `test/dummy/app/assets/tailwind/application.css`. After view markup changes:

```bash
cd test/dummy
bin/rails tailwindcss:build
```

Missing styles usually mean the `@source` paths did not match the installed gem path, or the dummy CSS was not rebuilt.

Location does not embed maps or load a mapping JavaScript SDK.
