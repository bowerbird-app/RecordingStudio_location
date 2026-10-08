# Recording Studio Location

Recording Studio Location stores a physical place as a normal Recording Studio recordable.

A location can sit under whatever host recordable a product allows: a press kit, a business, an event, a person, or anything else. Those meanings belong to the parent recording. This gem does not add business, event, or press-kit models. Maps stay out. Geocoding is optional and only runs when you call it.

## What you get

- gem name: `recording_studio_location`
- engine: `RecordingStudioLocation`
- recordable: `RecordingStudio::Location::Location`
- capability: `:location`, opted in with `RecordingStudio::Capabilities::Location.to`
- optional coordinates and a permissive address
- `display_name`, `full_address`, and `coordinates`
- optional `geocode!` / `reverse!` when a host assigns a geocoder
- optional place search (`#search` / `#details`) behind engine JSON endpoints
- FlatPack form fields, a search helper, and a read-only display partial

```text
Recording Studio
└── reusable Location recordable
      ├── structured place/address data
      ├── optional coordinates
      ├── formatting helpers
      ├── reusable edit UI
      └── reusable display UI
```

Several locations under one parent are several Location recordings. Order them with Recording Studio Orderable if a product needs a sequence. Access, publishing, and attachments stay in those addons.

## Installation

```ruby
gem "recording_studio", "~> 4.2"
gem "recording_studio_location"
gem "flat_pack"
```

```bash
bin/rails generate recording_studio_location:install
bin/rails generate recording_studio_location:migrations
bin/rails db:migrate
```

The install generator mounts `RecordingStudioLocation::Engine` and copies an initializer. The migrations generator copies `recording_studio_locations` into the host application. The host database owns the table.

Keep `config.require_recordable_declarations = true`.

## Enable it on a parent

Location is not a root recordable. It does not list host models such as `PressKit` or `Business`. Register the type, then enable `:location` on each recordable that may contain a place. Recording Studio derives the allowed parents from that capability.

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "RecordingStudio::Location::Location"
  ]
  config.require_recordable_declarations = true
end

class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", plural_label: "Workspaces", root: true

  include RecordingStudio::Capabilities::Location.to
end
```

The engine also registers `RecordingStudio::Location::Location` after the host initializers load. Enabling the capability is what makes a parent legal. A type without `:location` cannot contain a Location, and a Location cannot be a root.

```ruby
root = RecordingStudio.root_recording_for(workspace)

recording = root.record(RecordingStudio::Location::Location) do |location|
  location.name = "Melbourne Convention Centre"
  location.locality = "Melbourne"
  location.region = "Victoria"
  location.country_code = "AU"
end

recording.recordable.display_name
# => "Melbourne Convention Centre"
```

A second place is another `record` call on the same parent. Nothing in this gem models "multiple locations" as its own object.

Revising a location uses Recording Studio's snapshot history:

```ruby
root.revise(recording) do |location|
  location.postal_code = "3006"
end
```

## Fields

| Column | Notes |
| --- | --- |
| `name` | Optional. "Head Office", "Fitzroy Showroom". |
| `address_line_1`, `address_line_2` | Optional street lines. |
| `locality` | City, suburb, or town. |
| `region` | State, province, or region. |
| `postal_code` | Optional. |
| `country_code` | ISO 3166-1 alpha-2, such as `AU`. Stored as the code, not the country name. |
| `latitude` | Optional decimal, precision 10 scale 7. |
| `longitude` | Optional decimal, precision 11 scale 7. |

A location is valid with any subset of these. `Melbourne, Victoria, Australia` is enough. Coordinates alone are enough. A full street address is not required.

`country_code` must be two letters when it is present. Latitude must be between -90 and 90, and longitude between -180 and 180, when present. One coordinate without the other is stored, but `coordinates` returns nil until both exist.

Indexes: `country_code`, `locality`, and `name`. There is no PostGIS column and no radius search.

## Formatting

```ruby
location.display_name
# "Fitzroy, Victoria, Australia"
# "Melbourne Convention Centre"   when name is present
# "Melbourne, Australia"

location.full_address
# "12 Smith Street, Fitzroy VIC 3065, Australia"

location.coordinates
# [-37.798, 144.978]
# nil unless both latitude and longitude are present
```

`display_name` prefers `name`, then locality, region, and country, then a street line, then coordinates. Blank pieces are dropped, so you do not get `", , Australia"`.

`full_address` joins the street lines, then locality, region, and postal code as one segment, then the country name. It is a simple formatter, not a country-specific postal layout.

Country names come from a built-in ISO list. An unknown two-letter code is shown as the code.

`recordable_name` returns `display_name`, so Recording Studio's recording label follows the same text.

## UI

Two edit helpers. `recording_studio_location_fields(form)` is the original long form and stays unchanged.

```erb
<%= form_with model: location, url: location_path(recording), method: :patch do |form| %>
  <%= recording_studio_location_fields(form) %>
<% end %>
```

The partial is `recording_studio_location/locations/fields`. It uses FlatPack inputs. Coordinates sit last and are marked optional.

Search is a separate helper. The field is labelled Location. The user types a place, picks a result, and the structured fields are filled. When a search returns no results, the dropdown offers Add address manually, which opens a FlatPack modal. Saved places show a summary with Edit address. Hosts choose which helper to render.

```erb
<%= recording_studio_location_search_fields(form) %>
<%= recording_studio_location_search_fields(form, lookup: :address) %>
```

`lookup:` overrides `config.lookup_depth` for that form (`:full` by default, or `:address` for a cheaper address-only pick).

When no searchable adapter is configured, `recording_studio_location_search_fields` silently renders the full form.

Read-only display:

```erb
<%= recording_studio_location_display(location) %>
```

The card shows `display_name`, the formatted address when it adds detail, and coordinates only when both values exist. It does not embed a map.

The engine includes these helpers on Action Controller. Copy lives under `recording_studio_location.*` locale keys.

## Maps, geocoding, and search

There is no map embed. Saving a location never contacts a network service.

Leave credentials unset and `RecordingStudio::Location.geocoder` stays nil. `geocode!` / `reverse!` raise `Missing`. The search helper falls back to the full form.

To turn search and geocoding on, put the provider and key in Rails credentials:

```yaml
recording_studio_location:
  geocoder:
    provider: google
    api_key: "..."
```

Enable the Places API (legacy) on that key as well as Geocoding if you want as-you-type search. The API key never goes to the browser. Engine endpoints (`GET /recording_studio_location/searches` and `GET /recording_studio_location/places`) proxy the adapter after a logged-in user check.

```ruby
RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
  config.lookup_depth = :full # or :address
  # config.authenticate = ->(controller) { controller.authenticate_user! }
end
```

`lookup_depth` `:full` (default) loads venue name, address, and coordinates on pick. `:address` is cheaper and skips venue name. Override one form with `recording_studio_location_search_fields(form, lookup: :address)`.

Optional ENV overrides: `RECORDING_STUDIO_LOCATION_GEOCODER_PROVIDER` and `RECORDING_STUDIO_LOCATION_GEOCODER_API_KEY`. Assign any adapter that implements the surface: `#geocode`, `#reverse`, `#search`, `#details`, `#attribution`, `#capabilities`. Google is the first built-in. `RecordingStudioLocation::Geocoder::Fake` is for tests and the dummy app. Register another class with `RecordingStudioLocation::Geocoder.register("mapbox", MyAdapter)` or assign `config.geocoder = MyAdapter.new(...)`.

A pick fills the form fields from `#details`. Users can still edit or clear anything, including coordinates. Nothing is geocoded on save.

Call the bang methods inside `record` or `revise` when you want explicit forward/reverse geocoding. They apply attributes in memory and do not write Recording rows themselves.

```ruby
root.record(RecordingStudio::Location::Location) do |location|
  location.address_line_1 = "12 Smith Street"
  location.locality = "Fitzroy"
  location.region = "VIC"
  location.country_code = "AU"
  location.geocode!
end

root.revise(recording) do |location|
  location.reverse!
end
```

- `geocode!` sets latitude and longitude only. Address fields stay as the host typed them.
- `reverse!` fills blank address fields from the result. Non-blank fields stay put unless you pass `force: true`.
- Coordinates do not change on reverse.
- Missing adapter, blank query, no result, and provider errors raise.
- `#search` returns `[]` for unknown queries. It does not raise `NotFound`.

Tests should use `RecordingStudioLocation::Geocoder::Fake`. Do not hit a live provider from CI.

### Custom adapters

```ruby
class PhotonAdapter < RecordingStudioLocation::Geocoder::Adapter
  def search(query, **)
    # return Array<RecordingStudioLocation::Geocoder::Candidate>
  end

  def details(id, depth: :full, **)
    # return RecordingStudioLocation::Geocoder::Result
  end

  def geocode(query_or_location); end
  def reverse(latitude, longitude); end

  def attribution
    RecordingStudioLocation::Geocoder::Attribution.new(text: "© OpenStreetMap contributors")
  end

  def capabilities
    { search: true, details: true, lookup_depths: %i[full address] }
  end
end

RecordingStudioLocation.configure do |config|
  config.geocoder = PhotonAdapter.new(base_url: ENV.fetch("PHOTON_URL"))
end
```

Keep provider-specific HTTP and attribution inside the adapter. The search UI and engine endpoints only talk to this interface.

## Configuration

```ruby
RecordingStudioLocation.configure do |config|
  config.geocoder = RecordingStudioLocation::Geocoder.from_rails_credentials
  config.lookup_depth = :full
end
```

`config/recording_studio_location.yml` is loaded when the host has one. Unknown keys are ignored. Do not put the API key in YAML.

## Dummy app

`test/dummy` is a host, not a location product. Sign in as `admin@admin.com` / `Password`.

- `/` shows the seeded Melbourne Convention Centre recording under Studio Workspace
- `/locations/new` uses the search helper. Without a live key the dummy assigns `Geocoder::Fake.demo` so you can type "melbourne" or "fitzroy"
- `/locations/:id` uses the read-only display and names the parent recording

Workspace and Folder enable `:location`. Page does not, so a Location cannot be recorded under a Page.

## Composition

Use the same Location class under any recordable that enables the capability:

```text
Business
└── Location

PressKit
└── Location

Event
└── Location
```

Those parent classes live in the host or in another addon. They are not part of this gem.

Pair Location with the rest of Recording Studio when you need it:

- Accessible for who can see the recording
- Orderable when sibling places need a position
- Attachable for photos
- Publishable for a public page

Location does not reimplement those behaviors.

## Development

Engine internals for install, config, migrations, and local setup live in `docs/recording_studio_location/`.

The dummy app pins Recording Studio `v4.3.0`, Accessible `v0.10.1`, Root Switchable `v0.5.1`, and FlatPack `v0.1.196`. Location is `0.3.0`.

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

```bash
bundle exec rubocop
bundle exec rake app:test
```
