## Watering Hint / HUD Consistency Checklist

- [x] Fix WATER and CLONE label conditions — `lua/game/scenes/store_scene.lua` — in `_hud_labels()` (~line 493–495): add `and slot_item.ready` to the WATER guard; remove `and not held.loaded_plant` from the CLONE guard
