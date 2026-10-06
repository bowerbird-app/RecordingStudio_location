# GitHub Codespaces

## Quick start

1. Create a Codespace on this repository.
2. Wait for `postCreateCommand` (~3–5 minutes).
3. Start the dummy app:

```bash
cd test/dummy
bin/dev
```

4. Open forwarded port 3000. Sign in as `admin@admin.com` / `Password`.

## What runs automatically

`.devcontainer/devcontainer.json` `postCreateCommand`:

```bash
git lfs install && \
bundle config set --local path '/usr/local/bundle' && \
bundle install && \
cd test/dummy && \
bundle exec rails db:prepare && \
bundle exec rails tailwindcss:build
```

## Services

`.devcontainer/docker-compose.yml`:

| Service | Image | Port |
| --- | --- | --- |
| db | `postgres:16` | 5432 |
| redis | `redis:7-alpine` | 6379 |
| app | `.devcontainer/Dockerfile` | 3000 |

Inside the container: `DB_HOST=db`, `REDIS_URL=redis://redis:6379/0`, `CODESPACES=true`.

Dummy credentials are not decrypted until you set a Codespaces secret named `RAILS_MASTER_KEY` (shared RecordingStudio_* dummy master key) or write that key to `test/dummy/config/master.key`.

## CSRF

When `CODESPACES=true`, the dummy app relaxes the CSRF origin check so forwarded `*.app.github.dev` URLs work. Authenticity tokens stay required. See [SECURITY.md](SECURITY.md).

## Server

```bash
cd test/dummy
bin/dev
```

`Procfile.dev` runs Rails on `0.0.0.0` and the Tailwind watcher. Binding to `0.0.0.0` is required for port forwarding.

## Files

| File | Role |
| --- | --- |
| `.devcontainer/devcontainer.json` | Codespaces config |
| `.devcontainer/docker-compose.yml` | Postgres, Redis, app |
| `.devcontainer/Dockerfile` | Ruby image |
| `test/dummy/Procfile.dev` | `bin/dev` processes |
