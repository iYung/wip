# Water Drone — Implementation Checklist

Tasks marked as parallelizable can be worked simultaneously by separate agents.
Tasks with a "(depends on task N)" note must wait for that task to complete first.

---

## Group A — Data & Assets (parallelizable)

- [x] **A1** `lua/game/game_state.lua` ~line 72 (inside `GameState.new()`): Add `self.has_drone = false` after `self.seen_scripts = {}`.

- [x] **A2** `lua/game/game_state.lua` ~line 96 (inside `to_save` return table): Add `has_drone = gs.has_drone,` as a new key in the returned table, alongside the other scalar fields.

- [x] **A3** `lua/game/game_state.lua` ~line 114 (inside `GameState.from_save()`): Add `self.has_drone = data.has_drone or false` after the `seen_scripts` loop, before the `Store.new(...)` call, so older save files without this key default to `false`.

- [x] **A4** `lua/game/assets.lua` ~line 36 (after `A.intercom = img(...)`): Add `A.water_drone = try_img("assets/water_drone.png")` using `try_img` (not `img`) so the game does not crash if the art file is absent during development.

- [ ] **A5** `assets/water_drone.png`: Place the 60×60 px drone sprite (facing right) at this path. This is an art deliverable; the file must exist before the StoreScene draw step can be verified.

---

## Group B — WaterDrone Class (depends on A4 for the asset reference)

- [x] **B1** Create new file `lua/game/water_drone.lua`. The file must implement the full class described below. Do not add any source code until this checklist is confirmed; this task covers the complete file.

  Full class spec for `WaterDrone`:

  ```
  Fields:
    state        string   "idle" | "flying_to" | "watering"
    x            number   current world X (top-left of sprite)
    y            number   current world Y (fixed; set from drone_y on construction)
    drone_y      number   fixed world Y elevation — heat lamps are drawn at Y=80
                          in store_scene.lua (line 165); set drone_y = 80 so the
                          drone hovers at the same row (confirm against lamp image
                          height once art is available; adjust upward if overlap)
    target_slot  Slot|nil slot currently being flown to, nil when idle
    speed        number   300 (px/s)
    _water_timer number   countdown used in "watering" state (0.5 s)
    sprite       Sprite   Sprite.new(0, 0, 60, 60); sprite.image = A.water_drone
    _store_ref   Store    reference passed in from StoreScene

  Constructor:  WaterDrone.new(store, start_x)
    - start_x defaults to 0 (left edge) if not provided
    - state = "idle", x = start_x, y = drone_y
    - sprite.scale_x = 1 (facing right)

  WaterDrone:update(dt)
    State "idle":
      - Scan _store_ref.slots in order (ipairs); pick the first slot where
        slot.item ~= nil and slot.item.plant_type ~= nil and slot.item.ready == true.
      - If a target found: set target_slot = slot, set state = "flying_to",
        set sprite.scale_x = (slot.x < self.x) and -1 or 1.
      - If no target found: do nothing (hover in place).

    State "flying_to":
      - Move x toward target_slot.x by speed * dt.
        (x = x + math.min(speed*dt, target_slot.x - x) if moving right,
         x = x - math.min(speed*dt, x - target_slot.x) if moving left)
        Simpler: x = x + (target_slot.x - x) clamped so we do not overshoot.
      - Arrival check: if math.abs(self.x - target_slot.x) <= 4 then
          self.x = target_slot.x
          self._water_timer = 0.5
          self.state = "watering"

    State "watering":
      - _water_timer = _water_timer - dt
      - When _water_timer <= 0:
          local ok = target_slot.item ~= nil and target_slot.item:water()
          if ok then Sound.play("water_plant") end
          target_slot = nil
          state = "idle"
          (x stays at current position — no movement back to a home x)

  WaterDrone:draw()
    - sprite.x = self.x
    - sprite.y = self.y
    - sprite:draw()
  ```

  Required requires at top of file:
  ```lua
  local Sprite = require("lua/core/sprite")
  local Sound  = require("lua/game/sound")
  local A      = require("lua/game/assets")
  ```

---

## Group C — BuyScene Catalogue (parallelizable; depends on A4 for `A.water_drone`)

- [ ] **C1** `lua/game/scenes/buy_scene.lua` ~line 1 (top of file): Add `local WaterDrone = require("lua/game/water_drone")` to the require block. (WaterDrone is not actually instantiated here, but the kind="drone" branch in `_confirm` switches back to store_scene which triggers StoreScene to create it; no direct construction needed in buy_scene — this require can be omitted if StoreScene handles construction entirely. Verify during implementation.)

  > Note: The require of WaterDrone in buy_scene is NOT needed because `_confirm` for `kind="drone"` only sets `gs.has_drone = true` and switches scenes. The StoreScene constructs the drone object. Do not add this require unless buy_scene itself instantiates a WaterDrone.

- [x] **C2** `lua/game/scenes/buy_scene.lua` ~line 73 (after the Marketing entry, before `local PREVIEW_SIZE`): Add the Water Drone catalogue entry:

  ```lua
  CATALOGUE[#CATALOGUE + 1] = {
      label       = "Water Drone",
      description = "Auto-waters ready plants.",
      cost        = 10,
      kind        = "drone",
      image       = A.water_drone,
  }
  ```

  After this insertion the Water Drone will be catalogue index **14**.

- [x] **C3** `lua/game/scenes/buy_scene.lua` ~line 124 (`BuyScene:_confirm()`): Add a new `if` block for `kind == "drone"` before the `if gs.currency < ent.cost then return end` fallthrough. Insert after the `customer_cooldown` block (~line 159) and before the `gs.currency < ent.cost` check (~line 161):

  ```lua
  if ent.kind == "drone" then
      if gs.has_drone then return end
      if gs.currency < ent.cost then return end
      gs.currency  = gs.currency - ent.cost
      gs.has_drone = true
      Sound.play("shop_buy")
      self.scene_manager:switch(self.store_scene)
      return
  end
  ```

- [x] **C4** `lua/game/scenes/buy_scene.lua` ~line 233 (inside `BuyScene:draw()`, in the `else` branch that handles the default `display_cost`/`display_desc`): Add a new `elseif` branch for `kind == "drone"` before the `else` catch-all. Insert between the `elseif ent.kind == "customer_cooldown"` block and the final `else`:

  ```lua
  elseif ent.kind == "drone" then
      if gs.has_drone then
          display_cost = "---"
          display_desc = "Already installed."
          can_buy      = false
      else
          display_cost = "$" .. ent.cost
          display_desc = ent.description
          can_buy      = gs.currency >= ent.cost
      end
  ```

---

## Group D — StoreScene Integration (depends on B1 and A4; parallelizable within group)

- [x] **D1** `lua/game/scenes/store_scene.lua` ~line 1 (top of file, require block): Add:
  ```lua
  local WaterDrone = require("lua/game/water_drone")
  ```
  after the existing requires (e.g. after the `local COOLDOWN_TIERS` require on line 16).

- [x] **D2** `lua/game/scenes/store_scene.lua` ~line 57 (`StoreScene:on_enter()`): After the `self.drawer:add(self._plant_bubbles, 3)` line (~line 73) and before the `self.drawer:add(gs.player, 4)` line (~line 74), add the drone drawer registration:

  ```lua
  if self._drone then
      self.drawer:add(self._drone, 3.5)
  end
  ```

  Priority 3.5 places the drone above heat lamps (1.5) and plant_bubbles (3), and below the player (4). This matches the design doc spec.

- [x] **D3** `lua/game/scenes/store_scene.lua` ~line 68 (`StoreScene:on_enter()`): After the `self.drawer:clear()` line and the block that re-adds all drawables, add drone construction if not yet created:

  ```lua
  if gs.has_drone and not self._drone then
      self._drone = WaterDrone.new(gs.store, 0)
  end
  ```

  Place this before the `self.drawer:clear()` call (or after, since drawer:clear() only clears draw registrations, not the object itself). The drone object persists across on_enter/on_exit; only the drawer registration is cleared and re-added each time.

- [x] **D4** `lua/game/scenes/store_scene.lua` ~line 259 (`StoreScene:update(dt)`): After the `self._customer:update(dt)` call (~line 267), add:

  ```lua
  if self._drone then
      self._drone:update(dt)
  end
  ```

- [x] **D5** `lua/game/scenes/store_scene.lua` ~line 171 (`StoreScene:_setup_store()`, at the end of the function): In the `if self._from_save then` block (~lines 171-174), add a call to `self:_wire_drone()` after `self:_wire_intercom()`:

  ```lua
  if self._from_save then
      self:_wire_pc_store()
      self:_wire_intercom()
      self:_wire_drone()        -- add this line
  end
  ```

- [x] **D6** `lua/game/scenes/store_scene.lua` ~line 208 (after the `_wire_intercom` function, before `StoreScene:_next_customer_cfg()`): Add the new `_wire_drone` helper method:

  ```lua
  function StoreScene:_wire_drone()
      local gs = self.game_state
      if gs.has_drone and not self._drone then
          self._drone = WaterDrone.new(gs.store, 0)
      end
  end
  ```

---

## Group E — Tests (depends on B1; parallelizable within group)

Create new file `tests/test_water_drone.lua`. Pattern matches `tests/test_intercom.lua` — use `lua/headless/runner` and `runner.setup`. The file must cover the four scenarios below. CATALOGUE index for Water Drone is **14** (plants 1-6, WateringCan=7, Grafter=8, Intercom=9, ExpandSlot=10, Sneakers=11, HeatLamps=12, Marketing=13, WaterDrone=14).

- [x] **E1** Test: new drone starts in `"idle"` state

  ```
  Construct WaterDrone.new(store, 0) directly (no runner needed).
  Assert drone.state == "idle".
  Assert drone.x == 0.
  Assert drone.target_slot == nil.
  ```

- [x] **E2** Test: drone transitions to `"flying_to"` when a plant is ready

  ```
  Build a minimal store-like table: { slots = { {x=200, item={plant_type=1, ready=true}} } }
  Construct WaterDrone.new(store_stub, 0).
  Call drone:update(0) (zero-length tick so no movement occurs).
  Assert drone.state == "flying_to".
  Assert drone.target_slot == store_stub.slots[1].
  ```

- [x] **E3** Test: drone calls `water()` and plays sound on watering, then returns to idle

  ```
  Build a minimal store-like table with one slot whose item has:
    plant_type = 1, ready = true
    water = function(self) self.ready = false; return true end
  Construct WaterDrone.new(store_stub, 0).
  Force drone into watering state directly:
    drone.state = "watering"
    drone.target_slot = store_stub.slots[1]
    drone._water_timer = 0
  Call drone:update(1/60).
  Assert drone.state == "idle".
  Assert drone.target_slot == nil.
  Assert store_stub.slots[1].item.ready == false (water() was called).
  (Sound.play is a stub in headless env; assert it does not error.)
  ```

- [x] **E4** Test: drone returns to idle at current position, not a home X

  ```
  Same setup as E3 but set drone.x = 500 before triggering watering completion.
  After drone:update(1/60), assert drone.x == 500 (unchanged).
  ```

---

## Summary of new/changed files

| File | Action |
|------|--------|
| `lua/game/game_state.lua` | Change (tasks A1, A2, A3) |
| `lua/game/assets.lua` | Change (task A4) |
| `assets/water_drone.png` | New art file (task A5) |
| `lua/game/water_drone.lua` | New class file (task B1) |
| `lua/game/scenes/buy_scene.lua` | Change (tasks C2, C3, C4) |
| `lua/game/scenes/store_scene.lua` | Change (tasks D1, D2, D3, D4, D5, D6) |
| `tests/test_water_drone.lua` | New test file (tasks E1–E4) |
