# Upgrading

## 0.9.0

Bump to `0.9.0`. No Location migration.

Search and place endpoints require Accessible `:view` after sign-in. Dummy location pages and the recordings tree follow the same grants. Signed-in with no grant is denied.

Dummy pins Accessible `v0.24.2`, Metrics `v0.7.3`, Trashable `v0.12.3`, and Cache `v0.6.3`. Recording Studio stays `v6.1.0`.

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
