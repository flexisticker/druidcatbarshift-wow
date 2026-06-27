# Changelog

All notable changes to Druid CatBarShift will be documented here.

## [0.2.0-alpha] - 2026-06-27

### Fixed
- TOC referenced wrong filename (ProwlSwap.lua instead of DruidCatBarShift.lua) — caused LUA load error

### Added
- Config window in WoW style (`/dcbs`) to select action bar pages
- SavedVariables (DruidCatBarShiftDB) — settings persist across sessions
- IconTexture for addon list
- Slash command `/dcbs` to open/close config

## [0.1.0-alpha] - 2026-06-27

### Added
- Initial alpha release
- Automatic action bar switch to page 2 on Cat Form + Stealth (Prowl)
- Automatic switch back to page 1 when leaving Stealth or Cat Form
- Supports English (`Prowl`) and German (`Schleichen`) WoW clients
- Compatible with TBC Classic Anniversary Edition (Interface 20505)
