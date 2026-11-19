# Upgrading

## 0.14.0

Bump to `0.14.0`. No Location migration.

Development and dummy pins use Recording Studio `v7.8.0` and FlatPack `v0.2.0`. Gemspec floors stay `recording_studio >= 7.1, < 8.0` and `flat_pack >= 0.1.315`.

Dummy pins: Accessible `v0.55.0`, API `v1.19.0`, Admin `v2.19.1`, Logs `v0.8.2`, Moveable `v6.0.3`, Trashable `v1.2.3`, Cache `v0.7.1`, and Root Switchable `v0.16.1`. Metrics `v0.9.2` and Icons `v0.4.2` stay.

Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not.

flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration.

## 0.13.0

Bump to `0.13.0`. No Location migration.

`config.register_api_endpoints_on` chooses which Recording Studio APIs receive `location_geocode` and `location_reverse`. The default `:all` registers both endpoints on every API. A list of API names registers both only on those APIs. `false` or `[]` registers neither. Names, paths, inputs, and authorization are unchanged.

## 0.12.5

Bump to `0.12.5`. No Location migration. Names, paths, inputs, and authorization are unchanged.

Development and dummy pins use Recording Studio `v7.7.1` and FlatPack `v0.1.378`. Gemspec floors stay `recording_studio >= 7.1, < 8.0` and `flat_pack >= 0.1.315`.

Dummy pins: Accessible `v0.54.0`, API `v1.15.0`, Admin `v2.19.0`, Logs `v0.8.1`, Metrics `v0.9.2`, Moveable `v6.0.1`, Icons `v0.4.2`, and Trashable `v1.2.0`. Cache `v0.7.0` and Root Switchable `v0.16.0` stay.

Hosts that mount Recording Studio API 1.12 or newer need `config/recording_studio_api.yml`. `shared: {}` is enough to boot. Hosts on API 1.15 copy `20261117000024_add_owner_to_recording_studio_api_api_clients`.

## 0.12.4

Bump to `0.12.4`. No Location migration.

`location.api_payload` returns `latitude` and `longitude` as numbers, or null when absent. Hosts that read these two fields as strings now get numbers. Stored columns are unchanged.

## 0.12.3

Bump to `0.12.3`. No Location migration.

`location_geocode` and `location_reverse` keep the same names, paths, inputs, and authorization. Their OpenAPI tag is `Location`. Summaries are `Look up coordinates` and `Fill address from coordinates`, with no trailing period. Descriptions are unchanged.

## 0.12.2

Bump to `0.12.2`. No Location migration.

`location_geocode` and `location_reverse` keep the same names, paths, and inputs. Their OpenAPI descriptions now say when to use each tool, that `:id` is the Location recording id, and what the call returns. `force` still keeps existing address text unless it is true.

## 0.12.0

Bump to `0.12.0` with Recording Studio `>= 7.1, < 8.0`. No Location migration. On Recording Studio 7.2 or newer, run `20261116120000_add_recording_studio_events_timeline_index`.

`location_geocode` and `location_reverse` pass `recordable_type: "RecordingStudio::Location::Location"` and `required_role: :edit`. Recording Studio API scopes that `:id` and authorizes `:edit` before the handler. Handlers read `context.recording`. A foreign id, another recordable type, or a trashed location is 404.

When Recording Studio API is loaded, this gem requires `>= 1.1, < 2.0`. It is still not a gemspec dependency.

Dummy pins: Recording Studio `v7.3.0`, Accessible `v0.44.0`, Logs `v0.8.0`, Metrics `v0.9.0`, Moveable `v5.0.0`, Root Switchable `v0.16.0`, Trashable `v0.17.0`, and API `v1.1.0`. Admin `v2.16.0`, Cache `v0.6.3`, Icons `v0.2.1`, and FlatPack `v0.1.366` stay.

## 0.11.0

Bump to `0.11.0` with Recording Studio `>= 7.0, < 8.0`. No Location migration. Dummy lockfile updates `msgpack` to `1.8.7`.

`RecordingStudio.root_recording_for` only finds a root and returns `nil` when there is none. Seeds, setup, and request paths that created a root by looking it up call `create_root_recording!` with an actor. `authorize_write` must allow that create when `root_recording` is nil.

Dummy pins: Recording Studio `v7.0.0`, Accessible `v0.43.1`, Trashable `v0.16.1`, Admin `v2.16.0`, Root Switchable `v0.15.1`, and API `v0.23.4`. Metrics `v0.8.0`, Cache `v0.6.3`, Logs `v0.7.4`, Moveable `v4.1.1`, Icons `v0.2.1`, and FlatPack `v0.1.366` stay. With Trashable 0.16, use `Recording.kept` instead of `recording_studio_trashable_kept_sql`. API `v0.23.1` still calls that removed method, so the dummy pin is `v0.23.4`.

## 0.10.0

Bump to `0.10.0`. No Location migration.

Location lookups on Recording Studio API when that gem is loaded are `location_geocode` and `location_reverse`. Location is not an API recordable type. Place search and place details stay on the HTML engine. They are not API or MCP tools. `location_geocode` and `location_reverse` need `:edit` on the location.

Install Recording Studio API, enable `:api_access_point` on roots that hold API clients, and add `RecordingStudioApi::ApiClient` to `access_actor_types`. Dummy pins API `v0.21.3`, Admin `v2.12.0`, Logs `v0.7.4`, Moveable `v4.1.1`, Icons `v0.2.1`, and FlatPack `0.1.341`. Recording Studio stays `v6.5.0`. Copy API and Logs migrations if the dummy schema is your template.

## 0.9.0

Bump to `0.9.0`. No Location migration.

Search and place endpoints require Accessible `:view` after sign-in. Dummy location pages and the recordings tree follow the same grants. Signed-in with no grant is denied.

Dummy pins Accessible `v0.24.2`, Metrics `v0.7.3`, Trashable `v0.12.3`, and Cache `v0.6.3`. Recording Studio stays `v6.5.0`.

## 0.8.3

Bump to `0.8.3`. No Location migration.

Dummy sibling pins are unchanged from 0.8.2. Lockfiles use Rails 8.1.4.1.

## 0.8.2

Bump to `0.8.2`. No Location migration.

Dummy sibling pins are unchanged from 0.8.1.

## 0.8.1

Bump to `0.8.1`. No Location migration.

A selected place hides search and shows the summary. Address fields stay collapsed until Edit address or Add address manually, or until the record has errors. Hosts who copied the old partial should hide search when a place is selected and keep the address inputs in the DOM when collapsed. Rebuild Tailwind so `hidden` stays in the scan.

## 0.8.0

Bump to `0.8.0` with Recording Studio `>= 6.1.0` and FlatPack `>= 0.1.315`. No Location migration.

Call `recording_studio_layout` and set `content_for :title`. Remove `RecordingStudio::UsesDefaultLayout`, `recording_studio_page_nav`, and `layout "recording_studio/default_layout"`. If a host copied the dummy `recording_studio/_default_layout_head` partial, delete it so Flatpack CSS stays before `tailwind.css`.
