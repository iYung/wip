## Clear All Data Button Checklist

- [x] Task A — `web-template/controls.js` — rename button label from "Clear Save" to "Clear All Data", update the confirm dialog text to say "Delete your save and settings? This cannot be undone.", and after the existing `FS_unlink` call for `save.dat` add a second `FS_unlink` for `/home/web_user/love/game/settings.dat` wrapped in its own try/catch (missing file is silent). Sync and reload once after both deletions, same as today.
