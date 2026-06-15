## Goal

Fix two inconsistencies between the store HUD labels and what the player can actually do:

1. The WATER hint shows for any plant when holding a watering can, even when the plant isn't ready — the action silently does nothing in that case.
2. The CLONE hint condition references `held.loaded_plant`, a field that doesn't exist on `Grafter` (always nil) — dead code that should be removed.

## Affected files

- `lua/game/scenes/store_scene.lua` — `_hud_labels()`, lines ~493–495

## What changes

**Fix 1 — WATER:** Add `and slot_item.ready` to gate the hint on the plant's readiness:

```lua
-- before
elseif held and held.name == "Watering Can" and slot_item and slot_item.plant_type then

-- after
elseif held and held.name == "Watering Can" and slot_item and slot_item.plant_type and slot_item.ready then
```

**Fix 2 — CLONE:** Remove the dead `not held.loaded_plant` check:

```lua
-- before
elseif held and held.name == "Grafter" and not held.loaded_plant and slot_item and slot_item.stage == 3 then

-- after
elseif held and held.name == "Grafter" and slot_item and slot_item.stage == 3 then
```

## What stays the same

- `Plant.ready` flag and all watering logic in `plant.lua` — untouched.
- `Grafter:interact` and its no-space bubble feedback — untouched; the CLONE hint still shows even when all slots are full (intentional: the bubble is the feedback).
- All other HUD labels — untouched.

## Open questions

None.
