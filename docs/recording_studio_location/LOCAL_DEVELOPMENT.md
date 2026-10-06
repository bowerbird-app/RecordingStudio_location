# Local development

Work on Location outside Codespaces.

## Prerequisites

| Dependency | Version | Notes |
| --- | --- | --- |
| Ruby | 3.3+ | See `.ruby-version` |
| PostgreSQL | 16+ | UUID via `pgcrypto` |
| Redis | 7+ | Dummy Action Cable / cache |
| Node.js | 18+ | Dummy Tailwind CLI |

## Setup

```bash
git clone https://github.com/bowerbird-app/RecordingStudio_location.git
cd RecordingStudio_location
bundle install
```

Dummy credentials (`test/dummy/config/credentials.yml.enc`) use the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY`, or write that key to `test/dummy/config/master.key` (gitignored). Keep the encrypted file. Do not mint a per-repo key.

```bash
cd test/dummy
bin/rails credentials:show
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/dev
```

Open http://localhost:3000 and sign in as `admin@admin.com` / `Password`. The home page shows the seeded Melbourne Convention Centre location under Studio Workspace.

Adjust `test/dummy/config/database.yml` if local Postgres is not `postgres`/`postgres` on localhost.

## Tests and lint

From the gem root:

```bash
bundle exec rubocop
bundle exec rake test:all
```

`bundle exec rake app:test` runs the dummy suite.

## Environment

| Variable | Default | Role |
| --- | --- | --- |
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `postgres` | PostgreSQL user |
| `DB_PASSWORD` | `postgres` | PostgreSQL password |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis |
| `PORT` | `3000` | Dummy server |
| `RAILS_MASTER_KEY` | unset | Decrypts dummy credentials |

## Cursor Cloud Agents

Cloud Agents load skills from `.cursor/skills/` and plugin rules from `.cursor/rules/` at start.

`.cursor/environment.json` is repo-managed. `install` runs `.cursor/install.sh`, which provisions the stack then `.cursor/fetch-skills.sh`. If `RAILS_MASTER_KEY` is set, `install.sh` writes gitignored `test/dummy/config/master.key`.

`.cursor/skills/` and `.cursor/rules/` are gitignored. Do not vendor `SKILL.md` or `*.mdc` files.

## Layout

```
RecordingStudio_location/
├── app/views/recording_studio_location/locations/
├── db/migrate/
├── lib/recording_studio_location/
├── lib/recording_studio/location/
├── lib/generators/recording_studio_location/
├── docs/recording_studio_location/
├── test/dummy/
├── recording_studio_location.gemspec
└── README.md
```
