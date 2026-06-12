# Rename PC Store → Laptop Checklist

- [x] Task A — `lua/game/items/pc_store.lua` — change `self.name = "PC Store"` to `"Laptop"`
- [x] Task B — `lua/game/scenes/store_scene.lua` — change both `item.name == "PC Store"` guards to `"Laptop"` (lines 207 and 211)
- [x] Task C — `lua/game/game_state.lua` — change `item.name == "PC Store"` guard to `"Laptop"` (line 26)
- [x] Task D — `tests/test_buy_scene_position.lua` — change `slot.item.name == "PC Store"` check to `"Laptop"` (line 48)
- [x] Task E — `architecture.md` — update player-facing "PC Store" mentions to "Laptop"; leave class/internal symbol references unchanged
- [x] Task F — `game-design.md` — update "PC Store" player-facing mentions to "Laptop"
- [x] Task G — `coding-notes.md` — rename "PC Store Catalogue" section header to "Laptop Catalogue"
- [x] Task H — `CLAUDE.md` — update catalogue description rule and item list to say "Laptop" instead of "PC Store"
