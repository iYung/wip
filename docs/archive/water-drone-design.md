# Water Drone — Design Doc

## Goal

Add a **Water Drone** as a one-time purchase from the PC buy menu. Once purchased, a drone sprite appears at the top of the store scene, flies to any plant whose water-ready bubble is showing, waters it automatically, then returns to idle. This removes the manual watering loop for players who have reached mid-to-late game, letting them focus on selling and store management.

---

## Affected Files

| File | Change |
|------|--------|
| `lua/game/game_state.lua` | Add `has_drone = false` field; serialize/deserialize it in `to_save`/`from_save` |
| `lua/game/scenes/buy_scene.lua` | Add "Water Drone" entry to `CATALOGUE`; handle `"drone"` kind in `_confirm()` and `draw()` (sold-out state once purchased) |
| `lua/game/scenes/store_scene.lua` | Construct `WaterDrone` if `gs.has_drone` on enter; add it to the drawer; call its `update(dt)` each frame; re-create it on save-load via a new `_wire_drone()` helper |
| `lua/game/assets.lua` | Load `assets/water_drone.png` (and optionally `assets/water_drone_left.png` if the art requires two facing images instead of a flip) |

---

## New Files

| File | Purpose |
|------|---------|
| `lua/game/water_drone.lua` | `WaterDrone` class — state machine, movement, watering logic |
| `assets/water_drone.png` | Drone sprite (facing right; `scale_x = -1` flips to face left) |
| `tests/test_water_drone.lua` | Headless tests for drone state transitions and watering |

---

## Behavior Spec

### Idle position

The drone hovers at a **fixed world Y** just below the heat lamps row (confirm exact constant from code). It idles at whatever X it last stopped at — there is no home position. On first spawn the drone starts at the left edge of the store.

### Target selection

Each frame, while in the `"idle"` state, the drone scans `gs.store.slots` for the first slot whose item is a plant with `ready == true`. If multiple plants are ready simultaneously, the drone picks the **lowest-index ready slot** (leftmost). The drone does not queue multiple targets; it re-scans on each `idle` tick so newly-ready plants are picked up immediately.

### Movement

The drone moves at a **fixed speed** (suggested: 300 px/s) along the fixed elevation Y. It does not follow the camera — it exists in world space like every other drawable. The sprite's `scale_x` flips to `-1` when moving left, `1` when moving right, updated the moment a target is set.

**State machine:**

```
idle  (hover in place at current x)
  → (plant becomes ready) → flying_to
flying_to
  → (drone.x reaches target slot.x ± 4 px) → watering
watering
  → (0.5 s pause; call water(); play sound if successful) → idle  ← stays at current x
```

The drone's X is interpolated by `speed * dt` each frame toward the current target. A threshold of `±4 px` counts as "arrived."

### Watering

On entering the `"watering"` state the drone starts a 0.5 s timer. When the timer expires, it calls `slot.item:water()` and plays the `"water_plant"` sound if `water()` returns true. If `water()` returns `false` (plant manually watered before drone arrived), no sound plays. Either way the drone transitions to `idle` at its current position.

### Drawing

The drone is registered in the drawer at a priority **above heat lamps and below the player**. Confirm the exact priority values from the drawer registration calls in `store_scene.lua`.

The drone sprite size: **60 × 60 px** (3U × 3U).

### Multiple plants ready simultaneously

The drone handles one plant at a time. While `flying_to` or `watering` it ignores other ready plants. On entering `idle` it immediately re-scans, so it chains to the next ready plant without a gap.

---

## Data Model

### Purchase persistence

`GameState` gains one new boolean field:

```
gs.has_drone = false   -- default in GameState.new()
```

`GameState.to_save` serializes it as `has_drone = gs.has_drone`.  
`GameState.from_save` reads `data.has_drone` (defaulting to `false` if the key is absent, for backwards compatibility with existing save files).

### Drone runtime state

The drone is **not** serialized. It is a runtime object that lives entirely in `StoreScene`. On load, `_wire_drone()` (called from `_setup_store` when `_from_save == true`) constructs a fresh `WaterDrone` and adds it to the drawer if `gs.has_drone`. Its internal state (which plant it was flying to) is discarded on save; when the scene reloads the drone simply returns to idle and re-scans. Plant `ready` states are also reset on load (per existing save behavior), so there is nothing to re-target mid-flight.

### WaterDrone fields

| Field | Type | Purpose |
|-------|------|---------|
| `state` | string | `"idle"` / `"flying_to"` / `"watering"` |
| `x`, `y` | number | current world position (top-left of sprite) |
| `drone_y` | number | fixed world Y elevation (just below heat lamps row) |
| `target_slot` | Slot or nil | slot the drone is currently headed for |
| `speed` | number | movement speed in px/s (e.g. 300) |
| `_water_timer` | number | countdown in the `watering` state (0.5 s) |
| `sprite` | Sprite | 60×60, `A.water_drone` image |
| `_store_ref` | Store | reference to `gs.store` so update can scan slots |

### BuyScene catalogue entry

```lua
{
    label       = "Water Drone",
    description = "Auto-waters ready plants.",
    cost        = ???,   -- open question; see below
    kind        = "drone",
    image       = A.water_drone,
}
```

`_confirm()` for `kind == "drone"`:
- If `gs.has_drone` is already true: do nothing (sold-out guard).
- Deduct cost, set `gs.has_drone = true`, play `"shop_buy"`, switch back to `store_scene`.

`draw()` for `kind == "drone"`:
- If `gs.has_drone`: show `display_cost = "---"`, `display_desc = "Already installed."`, `can_buy = false`.
- Otherwise: normal price display.

### StoreScene integration

In `on_enter()`, after the drawer is populated:

```lua
if gs.has_drone then
    if not self._drone then
        self._drone = WaterDrone.new(gs.store, ...)
    end
    self.drawer:add(self._drone, 3.5)
end
```

In `update(dt)`:
```lua
if self._drone then
    self._drone:update(dt)
end
```

`_wire_drone()` for save-load path: same as the on_enter block — constructs `WaterDrone` if `gs.has_drone` and the drone does not already exist.

---

## Decisions (confirmed by user)

1. **Price:** $10 (testing value).
2. **Idle position:** World-space; drone stays wherever it last stopped — no forced return to a home position. May be off-screen; that is acceptable.
3. **Elevation:** Just below the heat lamps row. Confirm exact Y against the heat lamp Y constant in code; drone Y = heat_lamp_y + heat_lamp_height (on top of that row, drawn above it).
4. **Draw priority:** Above heat lamps, below player.
5. **Watering feedback:** `"water_plant"` sound only — no visual effect.
6. **Quantity:** One drone maximum. Re-purchase is blocked (sold-out display).
7. **No return flight:** After watering, state goes directly back to `idle` at the current position. Drone does not fly to a home position.

## Revised State Machine

```
idle  (hover in place at current x)
  → (plant becomes ready) → flying_to
flying_to
  → (drone.x reaches target slot.x ± threshold) → watering
watering
  → (0.5 s pause; call water(); play sound) → idle   ← stays at current x
```

The `flying_back` state is removed entirely. `idle_x` and `_water_timer` logic from the original spec that relates to a home position are not needed.
