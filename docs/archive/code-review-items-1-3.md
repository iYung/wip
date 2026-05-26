## Code Review Items 1–3 Checklist

- [x] **Item 1** — `lua/game/player.lua`, `lua/game/scenes/buy_scene.lua` — Rename `set_speed_level(level, color)` to `set_speed_color(color)` in `player.lua:47`, dropping the unused `level` param; update the call site at `buy_scene.lua:118` from `gs.player:set_speed_level(gs.speed_level, tier.color)` to `gs.player:set_speed_color(tier.color)`
- [x] **Item 2** — `lua/game/scenes/store_scene.lua` — Remove the trailing `slot` argument from the `BuyScene.new(...)` call at line 73; change `BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref, slot)` to `BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref)`
- [x] **Item 3** — `lua/game/assets.lua` — Delete line 33 (`A.grafter_loaded = img("assets/grafter_loaded.png")`); the asset is never referenced anywhere in the codebase
