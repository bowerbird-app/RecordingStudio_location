# Security notes

Location stores address text and optional coordinates. Geocoding is opt-in. With no provider and key, Location does not call a network service.

When a host assigns a geocoder and a person calls `geocode!` or `reverse!`, address text or coordinates go to that provider in the same request. Treat that as a data-sharing choice in the host's own policy.

Do not put the API key in YAML, git, docs, or logs. Use Rails credentials or the host secret store. Error messages from the Google adapter strip the `key` query parameter.

## Dummy app

- CSRF is on. In Codespaces only (`ENV["CODESPACES"] == "true"`), the origin check is relaxed so forwarded URLs work. Tokens stay required.
- Database passwords come from environment variables. Defaults are for local development.
- `test/dummy/config/credentials.yml.enc` uses the shared RecordingStudio_* development master key. `test/dummy/config/master.key` is gitignored. Do not commit secrets.
- Dummy credentials do not include a geocoder key, so the dummy initializer leaves `geocoder` nil.
- Gemspec sets `rubygems_mfa_required`.

## Hosts

- Grant access with Recording Studio Accessible. Do not add a parallel Location ACL.
- Treat address and coordinates as personal or business data in the host's own policy.
- Do not log full addresses from hooks in production.
- Tests should use `RecordingStudioLocation::Geocoder::Fake`. Do not call Google from CI.

Report issues through the maintainers' usual private channel, not a public GitHub issue that includes secrets.
