## Fix Swap HUD Label Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua:552` — change `slot_item.name` to `held.name` in the SWAP label
- [x] Task B — `tests/test_swap.lua:65,96` — update both SWAP assertions from "GARBAGE BIN" to "WATERING CAN" (the held item)
- [x] Task C — `tests/test_hud_labels.lua:180` — update SWAP assertion from "GRASS" to "WATERING CAN" (the held item)
