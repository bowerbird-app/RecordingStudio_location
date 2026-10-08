# Dummy App

This Rails app exists to validate Recording Studio Location in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace plus seeded folder and page recordables
- Recording Studio default layout, FlatPack assets, and Tailwind source scanning
- Mounted `RecordingStudio::Engine` and `RecordingStudioLocation::Engine`
- Seeded Melbourne Convention Centre location under Studio Workspace
- Dummy-only `/docs/*` pages for Location onboarding

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - seeded Location on Studio Workspace
- `/locations` - list locations in the workspace
- `/locations/new` - search helper (Fake demo adapter when no live key)
- `/locations/:id` - read-only display
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only Location pages
- `/up` - Rails health check

## Why This App Exists

Use this app to prove Location in a host: capability opt-in, search and form fields, and read-only display. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem wiring needs a look before a host copies it.

Authenticated pages use Recording Studio's shared default layout. Devise sign-in keeps `layouts/application`.

The home page in `app/views/home/index.html.erb` stays a minimal demo of Location. Dummy docs pages hold the longer explanations.

Workspace and Folder enable `:location`. Page does not, so a Location cannot be recorded under a Page.
