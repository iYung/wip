# Player Sounds Checklist

- [x] Task A — `lua/headless/stubs.lua` — Add a `love.audio` stub with `newSource` (returns a clonable stub source) and `play` as no-ops, so tests never hit real audio and Sound module guards work cleanly.

- [x] Task B — `lua/game/sound.lua` (new file) — Create the Sound singleton: `Sound.load()` iterates all 16 event names, calls `love.audio.newSource(path, "static")` for each file found via `love.filesystem.getInfo`, stores in a local table. `Sound.play(name)` clones the source and plays it. Both functions early-return when `love.audio` is nil. Call `Sound.load()` from `main.lua` inside `love.load`.

- [x] Task C — `assets/sounds/` (new directory + 17 files) — Created minimal valid silent `.wav` placeholder files (ffmpeg unavailable; WAV generated via Python wave module; Sound.lua updated to use `.wav` extension).

- [x] Task D — `lua/game/items/plant.lua` — (1) Make `Plant:water()` return `true` after a successful stage advance and `false` on the two early-return guards. (2) In `Plant:update()`, after `self.ready = true` and `self.bubble.visible = true`, call `Sound.play("plant_ready")`.

- [x] Task E — `lua/game/items/watering_can.lua` — In `WateringCan:interact()`, call `Sound.play("water_plant")` when `slot.item:water()` returns `true`.

- [x] Task F — `lua/game/items/grafter.lua` — In `Grafter:interact()`, call `Sound.play("clone_success")` after placing the clone into `best_slot`, and `Sound.play("clone_fail")` in the else branch (no empty slot).

- [x] Task G — `lua/game/scenes/store_scene.lua` — Add sound calls throughout the two handlers:
  - `_handle_pick_up_down`: `pick_up` after picking up, `put_down` after putting down, `dismiss_customer` after `customer:dismiss()`.
  - `_handle_interact`: `discard_plant` after the garbage-bin discard, `sell_plant` after `customer:serve()`, `dialogue_skip` after `skip_reveal()`, `dialogue_advance` after `customer:advance()`, `open_shop` when the pc_store interact triggers a scene switch.

- [x] Task H — `lua/game/scenes/buy_scene.lua` — Add sound calls: `shop_navigate` after left/right changes `self.selected`; `shop_close` after E key triggers the scene switch back to store; `shop_buy` at the end of a successful `_confirm` (after any early-return guards, before or after the switch back to store scene).

- [x] Task I — `lua/game/scenes/start_scene.lua` — Add sound calls: `menu_navigate` after up or down changes `self.selected`; `menu_confirm` at the start of `_confirm` (before branching on `self.selected`).
