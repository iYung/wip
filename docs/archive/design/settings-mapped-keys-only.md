## Goal

Remove hardcoded key fallbacks from the settings menu so that only the player's mapped keys work there — no phantom spacebar, Return, or arrow-key responses.

## Affected files

- `lua/game/scenes/settings_menu.lua`

## What changes

`settings_menu.lua` currently hard-wires extra keys on top of the player's mapped bindings:

**Navigation (up/down/left/right)**
```lua
-- current — arrow keys always fire regardless of mapping
local up = love.keyboard.isDown("up") or love.keyboard.isDown(kb.move_up or "w")
```
Arrow key prefixes will be removed; only the mapped key (with the nil-guard default) will be checked.

**Confirm**
```lua
-- current — Return and Space always fire regardless of mapping
local confirm = love.keyboard.isDown(kb.interact or "space")
             or love.keyboard.isDown("return") or love.keyboard.isDown("space")
```
The trailing `or love.keyboard.isDown("return") or love.keyboard.isDown("space")` will be removed; only the mapped interact key fires confirm.

These patterns appear in **four places** inside `settings_menu.lua`:
1. `open()` — initial key-state snapshot
2. `update()` main-menu block
3. `update()` keybinds sub-screen block
4. `_confirm()` — snapshot taken when entering the keybinds sub-screen

All four need the same cleanup.

The nil-guard fallbacks (`kb.interact or "space"`, `kb.move_up or "w"`, etc.) are kept — they protect against a nil key slot if save data is corrupt, and they are invisible during normal play because defaults are always set.

`escape` is not changed — it is not a remappable action and it is the only way to dismiss the menu without a confirmation.

## What stays the same

- `escape` always closes/backs out (no change)
- nil-guard defaults (`or "space"`, `or "w"`, etc.) stay as safety nets
- All drawing, volume controls, keybind capture flow, shake animation — untouched

## Open questions

None — user confirmed: lock out arrow keys and Return/Enter; only mapped keys should fire.
