# Security notes

Location stores address text and optional coordinates. Geocoding and place search are opt-in. With no adapter, Location does not call a network service. Saving a location never geocodes.

When a host assigns an adapter:

- `geocode!` / `reverse!` send address text or coordinates to that provider in the same request.
- The search helper sends the typed query to `GET /recording_studio_location/searches`, which calls `#search` server-side. A pick calls `GET /recording_studio_location/places`, which calls `#details`. The browser never receives the API key.

Treat those as data-sharing choices in the host's own policy.

Do not put the API key in YAML, git, docs, or logs. Use Rails credentials or the host secret store. Error messages from the Google adapter strip the `key` query parameter.

Search endpoints require a logged-in user (`config.authenticate`, Devise `authenticate_user!`, or 401). Queries shorter than 3 characters never reach the adapter. Autocomplete responses may be cached for 45 seconds without the key in the cache key.

A pick fills form fields only after the user chooses a result. Users can edit or clear every filled field, including coordinates.

## Dummy app

- CSRF is on. In Codespaces only (`ENV["CODESPACES"] == "true"`), the origin check is relaxed so forwarded URLs work. Tokens stay required.
- Database passwords come from environment variables. Defaults are for local development.
- `test/dummy/config/credentials.yml.enc` uses the shared RecordingStudio_* development master key. `test/dummy/config/master.key` is gitignored. Do not commit secrets.
- Dummy credentials do not include a provider key. The dummy initializer assigns `Geocoder::Fake.demo` in local environments so search can be demonstrated without a network call.
- Gemspec sets `rubygems_mfa_required`.

## Hosts

- Grant access with Recording Studio Accessible. Do not add a parallel Location ACL.
- Treat address and coordinates as personal or business data in the host's own policy.
- Do not log full addresses from hooks in production.
- Tests should use `RecordingStudioLocation::Geocoder::Fake`. Do not call a live provider from CI.

Report issues through the maintainers' usual private channel, not a public GitHub issue that includes secrets.
