# Changelog

All notable changes to Druid CatBarShift will be documented here.

## [0.2.3] - 2026-07-10

### Fixed
- TOC interface bumped to 20506 for WoW patch 2.5.6 — addon was flagged as outdated (Classic Era stays 11508)

## [0.2.2] - 2026-07-02

### Fixed
- Bar switch when becoming visible (hit/aura break): all triggers (UNIT_AURA, UPDATE_SHAPESHIFT_FORM, UNIT_SPELLCAST_SUCCEEDED) now schedule a delayed check (0.15s via OnUpdate) because UnitBuff is not yet updated when UNIT_AURA fires in TBC Classic

## [0.2.1] - 2026-07-02

### Fixed
- Bar switches back correctly after spell cast

## [0.2.0] - 2026-06-27

### Fixed
- TOC referenced wrong filename (ProwlSwap.lua instead of DruidCatBarShift.lua)

### Added
- Config window in WoW style (`/dcbs`) to select action bar pages
- SavedVariables (DruidCatBarShiftDB) — settings persist across sessions
- IconTexture for addon list
- WoW Classic Era support (`_Vanilla.toc`, Interface 11508)
- TBC Classic Anniversary explicit TOC (`_BCC.toc`, Interface 20505)
- X-Curse-Project-ID, X-GitHub, X-License metadata in all TOC files

## [0.1.0-alpha] - 2026-06-27

### Added
- Initial alpha release
- Automatic action bar switch to page 2 on Cat Form + Stealth (Prowl)
- Automatic switch back to page 1 when leaving Stealth or Cat Form
- Supports English (`Prowl`) and German (`Schleichen`) WoW clients
