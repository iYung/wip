## Goal

Persist game progress between sessions. A single save slot. Manual save in the settings menu plus auto-save on quit. Continue is grayed out on the start screen when no save exists.

---

## Affected files

- NEW `lua/game/save.lua`
- `lua/game/game_state.lua`
- `lua/game/scenes/store_scene.lua`
- `lua/game/scenes/start_scene.lua`
- `lua/game/scenes/settings_menu.lua`
- `main.lua`

---

## What changes

### `lua/game/save.lua` (new)

Three functions:

- `Save.exists()` → `bool` — checks for `save.dat` via `love.filesystem.getInfo`
- `Save.write(game_state)` → serializes game_state to `save.dat`
- `Save.read()` → returns a plain Lua table, or `nil` if no file

**Serialization format.** A Lua-loadable string written with `love.filesystem.write`. Loaded back with `load("return " .. content)()`. This avoids any third-party dependency.

```lua
return {
  version = 1,
  currency = 2500,
  speed_level = 1,
  growth_level = 0,
  cooldown_level = 2,
  growth_mult = 1.0,
  unlocked_plants = { [1]=true, [2]=true },
  stage3_counts   = { [1]=3 },
  seen_scripts    = { ["sage:1"]=true },
  player = { x=400.5, facing="right", held_item=nil },
  slots = {
    [1] = { item={ type="watering_can" } },
    [2] = { item={ type="garbage_bin" } },
    [3] = { item={ type="pc_store" } },
    [4] = { item={ type="plant", plant_type=2, stage=3 } },
    [5] = { item=nil },
  },
}
```

Item types: `"plant"` (with `plant_type`, `stage`), `"watering_can"`, `"grafter"`, `"garbage_bin"`, `"pc_store"`.

**Cooldown policy (per spec):** Cooldowns are NOT saved. On load, stage-1 and stage-2 plants restart their timers from scratch. `ready = false` for all loaded plants.

---

### `lua/game/game_state.lua`

Add two functions:

**`GameState.to_save(game_state)`** — extracts a plain serializable table from a live GameState. Iterates `store.slots` and `player.held_item`, converting each item to a `{ type=... }` record.

**`GameState.from_save(data)`** — reconstructs a live GameState from a plain save table. Creates Store with `#data.slots` slots. After constructing the player, applies the saved `speed_level` tier (speed value and color) if `speed_level > 0`. Reconstructs each item using a local `_item_from_data(d)` helper:
- `"plant"` → `Plant.new(d.plant_type)`, then set `stage`, call `sprite:set(tostring(stage))`
- `"watering_can"` → `WateringCan.new()`
- `"grafter"` → `Grafter.new()`
- `"garbage_bin"` → `GarbageBin.new()`
- `"pc_store"` → `PCStore.new(nil)` — factory is wired up later by StoreScene

Requires importing the item modules at the top of game_state.lua.

---

### `lua/game/scenes/store_scene.lua`

`StoreScene.new()` gains a `from_save` boolean parameter (default false).

`_setup_store()` currently does two things: place default items AND set up visuals (customer, wall, heat lamps, etc.). Split behaviour:

- **If `from_save = false`** (new game): place WateringCan/GarbageBin/PCStore into slots 1–3 as before, then set up visuals.
- **If `from_save = true`** (loaded save): skip default item placement, set up visuals, then call `_wire_pc_store()`.

**`_wire_pc_store()`** — iterates all slots and `player.held_item`, finds the PCStore instance, and sets its `buy_scene_factory` closure. The factory is identical to what new-game sets.

---

### `lua/game/scenes/start_scene.lua`

`on_enter()` calls `Save.exists()` and stores the result in `self._has_save`.

`_confirm()`:
- **New Game** (selected == 1): `GameState.new()` → `StoreScene.new(gs, input, sm, false)`
- **Continue** (selected == 2): if `not self._has_save`, do nothing (button is inert). Otherwise: `Save.read()` → `GameState.from_save(data)` → `StoreScene.new(gs, input, sm, true)`

`draw()`: Continue button renders at 50% alpha when `not self._has_save`.

---

### `lua/game/scenes/settings_menu.lua`

Add `"Save Game"` between "Keybinds" and "Exit Settings" in `ITEMS`. Accepts a new `on_save` callback in `SettingsMenu.new()`. When "Save Game" is confirmed, calls `on_save()`.

Only shown when in-game (not opened from start screen). Guard: check `not self._opaque` before enabling Save Game; if opaque (start screen), this item draws grayed and is skipped.

---

### `main.lua`

Pass a save callback to `SettingsMenu.new()`:

```lua
settings_menu = SettingsMenu.new(ss, input, function()
    local current = scene_manager and scene_manager.current
    if current and current.game_state then
        Save.write(GameState.to_save(current.game_state))
    end
end)
```

Add `love.quit()`:

```lua
function love.quit()
    local current = scene_manager and scene_manager.current
    if current and current.game_state then
        Save.write(GameState.to_save(current.game_state))
    end
end
```

---

## What stays the same

- `GameState.new()` unchanged — still creates a fresh default state
- All item classes unchanged — no serialize methods added to them; serialization lives entirely in `save.lua` / `game_state.lua`
- Customer / quest / script state is NOT saved — customers and quests reset each session
- `store.slot_width` and `INITIAL_SLOTS` constants stay as is; slot count is derived from saved slot count on load
- Settings (volume, keybinds, fullscreen) are separate from game save — not included

---

## Web compatibility

`love.filesystem.write()` uses browser IndexedDB on web builds (love.js). The same Lua code works unchanged. The auto-save on `love.quit()` may not fire reliably in browser tabs; the manual "Save Game" button is the primary save path for web players.

---

## Open questions

None — all resolved before writing this doc.
