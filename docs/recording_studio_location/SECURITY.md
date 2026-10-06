# Security notes

Location stores address text and optional coordinates that the host already collected. This version does not call a geocoder, map provider, or other network service.

## Dummy app

- CSRF is on. In Codespaces only (`ENV["CODESPACES"] == "true"`), the origin check is relaxed so forwarded URLs work. Tokens stay required.
- Database passwords come from environment variables. Defaults are for local development.
- `test/dummy/config/credentials.yml.enc` uses the shared RecordingStudio_* development master key. `test/dummy/config/master.key` is gitignored. Do not commit secrets.
- Gemspec sets `rubygems_mfa_required`.

## Hosts

- Grant access with Recording Studio Accessible. Do not add a parallel Location ACL.
- Treat address and coordinates as personal or business data in the host's own policy.
- Do not log full addresses from hooks in production.

Report issues through the maintainers' usual private channel, not a public GitHub issue that includes secrets.
