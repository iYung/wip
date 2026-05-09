# MVP Steps

Goal: one plant type, full grow loop, core input and scene switch working end to end.

---

## Step 1 — Project Skeleton

- [ ] Create `main.lua` with empty `love.load`, `love.update`, `love.draw`
- [ ] Confirm Love2D runs and opens a window

---

## Step 2 — Core: Sprite

- [ ] Implement `Sprite` class
- [ ] Load a placeholder image and render it at a fixed position
- [ ] Confirm image appears on screen

---

## Step 3 — Core: Drawer

- [ ] Implement `Drawer` class with `add` and `draw`
- [ ] Add the placeholder Sprite to a Drawer and call `drawer:draw()` from `love.draw`
- [ ] Confirm priority ordering works with two test sprites

---

## Step 4 — Core: Camera

- [ ] Implement `Camera` with `attach`, `detach`, `follow`
- [ ] Hook camera into the draw loop around `drawer:draw()`
- [ ] Move camera position each frame and confirm world scrolls correctly

---

## Step 5 — Core: SpriteSet

- [ ] Implement `SpriteSet` with `add`, `set`, `draw`
- [ ] Test with two placeholder frames, switch between them on a keypress
- [ ] Confirm only the active frame renders

---

## Step 6 — Core: Scene and SceneManager

- [ ] Implement `Scene` base class and `SceneManager` with `switch`, `update`, `draw`
- [ ] Create a stub `StoreScene` and confirm the scene loop runs
- [ ] Confirm `on_enter` / `on_exit` fire correctly on switch

---

## Step 7 — Game: Input

- [ ] Implement `Input` with `update`, `is_down`, `pressed`
- [ ] Map arrow keys / WASD to `move_left` / `move_right` and a key each for `pick_up_down` and `interact`
- [ ] Log actions to console to confirm all four fire correctly

---

## Step 8 — Game: Player

- [ ] Implement `Player` with position, `update(dt, input)`, and `draw`
- [ ] Player moves left/right via Input
- [ ] Placeholder SpriteSet for the player character (two frames a/b)
- [ ] Add Player to StoreScene's Drawer at priority 2

---

## Step 9 — Game: Camera Follows Player

- [ ] Call `camera:follow(player)` in StoreScene's update
- [ ] Confirm camera centers on player as they move

---

## Step 10 — Game: Slot and Store

- [ ] Implement `Slot` with index, x position, item, and `draw`
- [ ] Implement `Store` with a fixed slot array (e.g. 8 slots), `slot_at(x)`, and `draw`
- [ ] Render store slots at priority 0 in the Drawer
- [ ] Confirm slots render and `slot_at` returns the correct slot for the player's x

---

## Step 11 — Game: GameState

- [ ] Implement `GameState` holding `store`, `player`, and `currency`
- [ ] Pass `game_state` into `StoreScene`
- [ ] Confirm store and player are accessible from the scene

---

## Step 12 — Game: Pick Up / Put Down

- [ ] Implement `Player.held_item`, pick up logic from active slot, put down into active slot
- [ ] Render held item above player (offset) when carried
- [ ] Confirm item moves between slot and player correctly

---

## Step 13 — Game: Plant

- [ ] Implement `Plant` with `plant_type = 1`, three stage sprites (placeholders), cooldown timer
- [ ] Implement `update(dt)` countdown and `ready` flag
- [ ] Implement `bubble` Sprite shown when ready
- [ ] Place a plant in one slot manually, confirm timer counts down and bubble appears

---

## Step 14 — Game: Watering Can

- [ ] Implement `WateringCan` item
- [ ] `interact()` calls `plant:water()` on the item in the active slot
- [ ] Confirm watering a ready plant advances its stage and hides the bubble
- [ ] Confirm watering a non-ready plant does nothing

---

## Step 15 — Game: BuyScene

- [ ] Implement `BuyScene` with a minimal UI (list of plants, confirm/cancel)
- [ ] PC Store item triggers `scene_manager:switch(BuyScene)` when interacted with from a slot
- [ ] On exit, switch back to `StoreScene`
- [ ] Purchased plant placed into the slot the player is standing on (or first empty slot)

---

## Step 16 — End-to-End Pass

- [ ] Place PC Store and watering can in the starting store
- [ ] Buy a plant from BuyScene, place it, wait for cooldown, water it through all three stages
- [ ] Confirm the full loop works without errors

---

## Cut from MVP

- Grafter
- Store growth (fixed slot count only)
- Currency and harvesting
- Plant types 2–6
- Multiple plant instances (only need to verify one works)
