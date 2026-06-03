# Settings Menu Sounds

## Goal
Play the same navigation and confirm sounds in the settings menu that already play in the start menu, so the UI feels consistent.

## Affected files
- `lua/game/scenes/settings_menu.lua`

## What changes
`settings_menu.lua` currently has no sound calls. We add `Sound = require("lua/game/sound")` at the top and insert `Sound.play(...)` calls at every user-action site:

| Action | Sound | Where in code |
|---|---|---|
| Navigate up/down (main screen) | `menu_navigate` | `update()` up/down edge-detect blocks |
| Navigate up/down (keybinds subscreen) | `menu_navigate` | keybinds branch up/down edge-detect blocks |
| Confirm selection (main screen) | `menu_confirm` | `_confirm()` entry |
| Confirm / select row (keybinds subscreen) | `menu_confirm` | keybinds branch confirm edge-detect block |
| Volume left/right step (SFX or Music) | `menu_navigate` | left/right edge-detect blocks for `selected == 2` and `selected == 3` |

Escape / close does **not** play a sound (same as start scene — only confirms play `menu_confirm`).

## What stays the same
- Sound event names (`menu_navigate`, `menu_confirm`) are unchanged.
- The `Sound` module interface is unchanged.
- No new assets needed.
- All other settings menu behaviour (keybinds capture, fullscreen toggle, volume clamping) is untouched.

## Open questions
None — volume sliders confirmed to play `menu_navigate` per step.
