# Upgrading

## 0.8.2

Bump to `0.8.2`. No Location migration.

The install generator writes Tailwind `@source` lines from `RecordingStudioLocation::Engine.root` (and FlatPack’s engine root) instead of a hard-coded `/usr/local/bundle` path. Re-run `bin/rails generate recording_studio_location:install` if you want those lines rewritten. Dummy sibling pins are unchanged from 0.8.1.

## 0.8.1

Bump to `0.8.1`. No Location migration.

A selected place hides search and shows the summary. Address fields stay collapsed until Edit address or Add address manually, or until the record has errors. Hosts who copied the old partial should hide search when a place is selected and keep the address inputs in the DOM when collapsed. Rebuild Tailwind so `hidden` stays in the scan.

## 0.8.0

Bump to `0.8.0` with Recording Studio `>= 6.1.0` and FlatPack `>= 0.1.315`. No Location migration.

Call `recording_studio_layout` and set `content_for :title`. Remove `RecordingStudio::UsesDefaultLayout`, `recording_studio_page_nav`, and `layout "recording_studio/default_layout"`. If a host copied the dummy `recording_studio/_default_layout_head` partial, delete it so Flatpack CSS stays before `tailwind.css`.
