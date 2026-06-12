# Rename PC Store → Laptop

## Goal

Change the player-visible name of the PC Store item from `"PC Store"` to `"Laptop"`. Internal identifiers (class, file, asset key, save key, function names) stay unchanged.

## Affected files

| File | Change |
|------|--------|
| `lua/game/items/pc_store.lua` | `self.name = "Laptop"` |
| `lua/game/scenes/store_scene.lua` | Two `name == "PC Store"` string guards → `"Laptop"` |
| `lua/game/game_state.lua` | One `item.name == "PC Store"` guard → `"Laptop"` |
| `tests/test_buy_scene_position.lua` | One `name == "PC Store"` check in test assertion → `"Laptop"` |
| `architecture.md` | Player-facing mentions of "PC Store" → "Laptop"; class/internal refs unchanged |
| `game-design.md` | User-facing "PC Store" mentions → "Laptop" |
| `coding-notes.md` | "PC Store Catalogue" section header → "Laptop Catalogue" |
| `CLAUDE.md` | Catalogue description rule and item list mention → "Laptop" |

## What changes

- The in-game item name string `"PC Store"` becomes `"Laptop"` everywhere it is used as a display name or matched as a string identity check.
- Live documentation updated to reflect the new name.

## What stays the same

- Class name: `PCStore`
- File name: `lua/game/items/pc_store.lua`
- Asset key: `A.pc_store` / PNG `pc_store.png`
- Save serialization key: `"pc_store"` (no save-file breakage)
- Function name: `_wire_pc_store` in `store_scene.lua`
- HUD action label: `"OPEN SHOP"` (unchanged)
- Archive docs (historical, not live)
- Test comments referencing "PCStore" as a code symbol (those are comments, not string checks)

## Open questions

None — resolved before writing this doc.
