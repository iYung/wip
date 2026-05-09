# Grafter Steps

Goal: grafter splits a plant into two — original resets to stage 1, clone is stored inside the grafter. Placing the loaded grafter puts the clone into a slot and empties the grafter back into the player's hand.

---

## Mechanic Summary

| Action | Result |
|--------|--------|
| Hold grafter + F on a plant slot | Plant resets to stage 1; clone stored in grafter (loaded) |
| Hold loaded grafter + E over empty slot | Clone placed in slot; grafter empties, stays in hand |
| Hold grafter + F on empty slot | Nothing |
| Hold grafter + F when already loaded | Nothing |

---

## Step 1 — Grafter Class

- [ ] Create `lua/game/items/grafter.lua`
- [ ] Properties: `loaded_plant` (nil or Plant), `carriable = true`
- [ ] Sprite: distinct color (e.g. orange) when empty, different color when loaded
- [ ] `interact(player, store, scene_manager)`:
  - Return early if not held by player
  - Return early if already loaded
  - Return early if active slot has no plant
  - Set `plant.stage = 1`, reset `plant.cooldown` to stage-1 cooldown, clear `plant.ready` and `plant.bubble.visible`, reset sprite to `"1"`
  - Create `Plant.new(plant.plant_type)`, store in `self.loaded_plant`
  - Update sprite color to show loaded state

---

## Step 2 — Modified Pick Up / Put Down

- [ ] In `StoreScene:_handle_pick_up_down()`, add a check before the normal path:
  - If `player.held_item` is a loaded Grafter and slot is empty:
    - Place `grafter.loaded_plant` into slot
    - Set `grafter.loaded_plant = nil`
    - Grafter stays in `player.held_item` (do not change held item)
    - Return early (skip normal put-down logic)
- [ ] Confirm normal pick up / put down still works for all other items

---

## Step 3 — Place in Store

- [ ] Add `Grafter.new()` to a slot in `StoreScene:_setup_store()` (e.g. slot 5)
- [ ] Require grafter in store_scene.lua

---

## Step 4 — End-to-End Test

- [ ] Pick up grafter from slot 5
- [ ] Buy and place a plant, water it through stages
- [ ] Hold grafter, press F on the plant slot — plant resets to stage 1, grafter turns loaded color
- [ ] Walk to an empty slot, press E — clone placed in slot, grafter empties back to orange
- [ ] Confirm both plants grow independently from stage 1
- [ ] Confirm grafter does nothing when already loaded
- [ ] Confirm grafter does nothing on an empty slot
