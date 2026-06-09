# Design: Clear All Data Button

## Goal

The web build's "Clear Save" button only deletes `save.dat`. Now that settings are persisted to `settings.dat` (via `feature/settings-persistence`), testers need a way to wipe both files at once so they can start fully fresh.

## Affected files

- `web-template/controls.js` — the only file that needs to change

## What changes

- Rename the button label from "Clear Save" to "Clear All Data"
- Update the confirm dialog text to reflect both files being deleted
- After the existing `FS_unlink` call for `save.dat`, add a second `FS_unlink` call for `settings.dat` (path: `/home/web_user/love/game/settings.dat`); wrap it in its own try/catch so a missing settings file is silently ignored
- Sync and reload once after both deletions (existing flow unchanged)

## What stays the same

- Button placement, styling, and the `#save-controls` container
- The `FS_syncfs` → `location.reload()` pattern after deletion
- Everything in `index.html`, `build_web.sh`, and all Lua code

## Open questions

None.
