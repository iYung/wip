# Cashier Zone Steps

Goal: a walkable zone to the left of the store (negative x space) containing a customer window. Customers appear periodically and request a Fern via speech bubble. Selling to them pays 2× the normal sell value.

---

## World Layout

```
  [ cashier zone ][ slot 1 ][ slot 2 ] ...
  x = -400       x = 0
```

- Zone spans `x = -ZONE_WIDTH` to `x = 0`. `ZONE_WIDTH = 2 × slot_width` (400px).
- The counter/window sits at the same y as the store slots (`SLOT_Y = 600`), so it reads as one continuous floor.
- Customer sprite appears centered in the zone at counter height.
- Player left bound extends to `-ZONE_WIDTH + W/2` so the player can walk fully in.

---

## Customer Behavior

- One customer at a time. New one spawns after a random interval (15–30s) once the previous is fully gone.
- Walks in from the left (off-screen) to the counter at the center of the zone, then stops.
- Speech bubble appears only once the customer has arrived.
- Requests a **Fern** (plant_type 1), any stage accepted.
- On sale: walks back out to the left and disappears off-screen. Spawn timer resets once fully gone.
- Sale value = `plant_sell_value(plant) × 2`.

---

## Step 1 — Zone Constants & Player Bounds

- [ ] Add `ZONE_WIDTH = 2 * slot_width` as a constant in `store_scene.lua` (or `config.lua`).
- [ ] In `Player:update()`, replace the hardcoded left bound `W / 2` with `-ZONE_WIDTH + W / 2` — pass zone width in or read from config.
- [ ] Confirm the camera follow still works (no changes needed — camera follows player x, which can now go negative).

---

## Step 2 — Zone Background

- [ ] In `StoreScene:draw()`, before the camera detach, draw the zone floor rectangle from `x = -ZONE_WIDTH` to `x = 0` at `SLOT_Y`, same height as the store slots. Use a slightly different color to distinguish it from the store.
- [ ] Draw a counter/window sprite (rectangle) centered in the zone at `SLOT_Y` — this is where the customer will stand.

---

## Step 3 — Customer Class (`lua/game/customer.lua`)

**State** — one of `"idle"`, `"walking_in"`, `"waiting"`, `"walking_out"`

**Properties**
- `state` — current state string
- `plant_type` — integer, always 1 (Fern) for now
- `x`, `y` — world position
- `target_x` — counter position (center of zone), the walk-in destination
- `exit_x` — off-screen left position, the walk-out destination
- `speed` — movement speed (e.g. 80 px/s)
- `sprite` — Sprite following `x`/`y`
- `bubble` — Sprite above the customer; only visible in `"waiting"` state

**Methods**
- `new(target_x, exit_x, y)` — constructor; `state = "idle"`
- `show(plant_type)` — set `plant_type`, place customer at `exit_x`, set `state = "walking_in"`
- `serve()` — set `state = "walking_out"` (called on successful sale)
- `update(dt)`:
  - `"walking_in"`: move right toward `target_x`; on arrival set `state = "waiting"`, show bubble
  - `"walking_out"`: move left toward `exit_x`; on arrival set `state = "idle"`, hide sprite and bubble
  - others: no-op
- `arrived()` — returns `state == "waiting"`
- `active()` — returns `state ~= "idle"`
- `draw()` — draw sprite if not idle, draw bubble if `"waiting"`

---

## Step 4 — Spawn System in StoreScene

- [ ] Add `self._customer` (Customer instance) in `StoreScene:on_enter()` / `_setup_store()`, passing `target_x = -ZONE_WIDTH / 2` and `exit_x = -ZONE_WIDTH - sprite_width`.
- [ ] Add `self._spawn_timer` initialized to a random value in `[15, 30]`.
- [ ] In `StoreScene:update(dt)`:
  - Always call `_customer:update(dt)`
  - Count down `_spawn_timer` only when `not _customer:active()`
  - When timer hits 0: call `_customer:show(1)`, reset timer to next random interval
- [ ] Add `_customer` to the drawer so it renders in world space.

---

## Step 5 — Sale Interaction

- [ ] In `StoreScene:_handle_interact()`, add a cashier check **before** the existing sell-bin branch:
  - Conditions: `player.x < 0` (in zone) AND `_customer:arrived()` AND `player.held_item` AND `player.held_item.plant_type == _customer.plant_type`
  - On match: pay `plant_sell_value(held) * 2`, clear `player.held_item`, call `_customer:serve()`
  - `return` after handling so the normal interact path doesn't fire.

---

## Step 6 — Context HUD

- [ ] In `StoreScene:_hud_labels()`, add a cashier F label check before all other F rules:
  - Conditions: `player.x < 0` AND `_customer:arrived()` AND `held` AND `held.plant_type == _customer.plant_type`
  - Label: `"F: SELL TO CUSTOMER ($" .. plant_sell_value(held) * 2 .. ")"`
- [ ] No HOVER label in the zone (no slot.item), so HOVER stays hidden — that's correct.

---

## Step 7 — End-to-End Test

- [ ] Walk left past x=0 — player enters zone smoothly, camera follows.
- [ ] Wait for customer to spawn (or shorten timer temporarily) — customer walks in from the left.
- [ ] Verify speech bubble only appears once customer reaches the counter.
- [ ] Walk in holding a Fern while customer is still walking in — no F label yet.
- [ ] Wait for customer to arrive — `F: SELL TO CUSTOMER ($X)` appears when holding Fern.
- [ ] Walk in holding a non-Fern plant — no F label shown.
- [ ] Press F with Fern — currency increases by 2×, customer walks back out left.
- [ ] Spawn timer resets once customer is fully off-screen. Next customer arrives after 15–30s.
- [ ] Walk in with empty hands — no F label, no crash.

---

## Open Questions

- Should the customer have a leave timer (patience)? If so, they disappear after N seconds unsatisfied and the next spawn is delayed.
- Should the requested plant type vary, or always be Fern?
- Should stage matter (e.g., customer only wants stage 3)?
