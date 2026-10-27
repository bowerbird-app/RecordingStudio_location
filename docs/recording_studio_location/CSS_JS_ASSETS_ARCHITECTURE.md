# Location assets

Location ships FlatPack ERB partials and a Stimulus controller for place search. It does not ship a compiled CSS bundle or a mapping SDK.

The field copies FlatPack Search chrome: `IconComponent` `magnifying-glass`, `--search-input-*` / `--search-padding-*` tokens, no chevron. SearchInput and Search cannot host this control as wrappers (see below). The dropdown still copies FlatPack Combobox listbox markup, option classes, surface tokens, and overlay motion (`playOverlayEnter` / `playOverlayExit`).

SearchInput is a named form control (`type="search"`, trailing clear, no leading icon). Search is nav live-search (`{title, description, url}` rows that navigate). Combobox filters a static `options:` list behind a chevron trigger. Select remote search loads `{value, label}` into a closed trigger. None of those fill structured address fields or accept `role="combobox"` on the input without taking over submit/clear/navigation. Location keeps its Stimulus controller.

A first-class FlatPack component would need a remote search field that looks like Search, exposes combobox/listbox semantics on the input, and emits the picked row (id/label plus a details callback) without submitting a single hidden value.

Clear location is a FlatPack icon-only ghost `Button` (`x-mark`, `aria-label` from i18n) on the saved-place summary. Search and SearchInput both ship an in-field clear that only empties the query; using that would desync the picked place. The summary X empties structured fields, hides the summary, the inline address fields, and the map, and focuses the search field. Add address manually is a secondary button under the search, and the same label in the no-results list. Both reveal the address fields in place. There is no modal in this partial.

The pin preview is an iframe sized with FlatPack radius/border tokens. FlatPack has no map component. The iframe `src` comes from `config.map` (`url_template` with `{lat}` / `{lng}`). No adapter, or missing coordinates, means no `src` and no map request. `tabindex="-1"` keeps it out of the tab order.

- Form: `app/views/recording_studio_location/locations/_fields.html.erb`
- Identity: `app/views/recording_studio_location/locations/_identity_fields.html.erb` — Title (TextInput), Type (RadioGroup `variant: :inline`, icon + label), and in `:choose` mode the same RadioGroup for `allowed_icons`. Radios stay real inputs (`sr-only` in the visual face).
- Search: `app/views/recording_studio_location/locations/_search_fields.html.erb`
- Map: `app/views/recording_studio_location/locations/_map.html.erb`
- Display: `app/views/recording_studio_location/locations/_display.html.erb` — address text, then the map in column 1 of a two-column grid. No card and no coordinate line.
- Stimulus: `app/javascript/recording_studio_location/controllers/place_search_controller.js`
- Stimulus: `app/javascript/recording_studio_location/controllers/identity_controller.js` — type change preselects an icon in `:choose` mode

Helpers `recording_studio_location_fields`, `recording_studio_location_search_fields`, and `recording_studio_location_display` include those partials from the host.

## Importmap

The install generator appends:

```ruby
pin_all_from RecordingStudioLocation::Engine.root.join("app/javascript/recording_studio_location/controllers"), under: "controllers/recording_studio_location", to: "recording_studio_location/controllers"
```

The engine adds `app/javascript` to `config.assets.paths`. Dummy `config/importmap.rb` has the same pin. Controller identifiers are `recording-studio-location--place-search` and `recording-studio-location--identity`.

Host apps already lazy-load `controllers` the way they load FlatPack.

## Tailwind

The host Tailwind build must scan the gem views and FlatPack components. The install generator adds `@source` lines to `app/assets/tailwind/application.css` when that file exists.

Dummy app sources live in `test/dummy/app/assets/tailwind/application.css`. `bin/rails tailwindcss:build` links `vendor/engines/flat_pack` and `vendor/engines/recording_studio` to the installed engines, then scans them. `rake test:dummy` and `rake app:test` run that build before the dummy suite.

```bash
cd test/dummy
bin/rails tailwindcss:build
```

Recording Studio's default layout already links `flat_pack/application.css` before `tailwind.css`. Do not add `recording_studio/_default_layout_head` to link Flatpack again. That second sheet loads Tailwind preflight (`* { padding: 0 }`) after the utilities, so form padding and radius disappear.

Missing styles usually mean the engine symlink points at an old checkout, or the dummy CSS was not rebuilt.

Location does not embed maps or load a mapping JavaScript SDK. Place search calls engine JSON endpoints, not a provider from the browser.
