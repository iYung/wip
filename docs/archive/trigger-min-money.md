## Trigger Min Money Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_next_customer_cfg()` around line 283, extend the trigger condition to also check `min_money`: change `if (gs.stage3_counts[t.plant_type] or 0) >= t.count then` to `if (gs.stage3_counts[t.plant_type] or 0) >= t.count and (not t.min_money or gs.currency >= t.min_money) then`

- [x] Task B — `lua/game/data/customer_scripts.lua` — Add `min_money` to five chapter triggers:
  - `sage:2` trigger → `{ plant_type = 1, count = 3, min_money = 5 }`
  - `sage:4` trigger → `{ plant_type = 3, count = 1, min_money = 20 }`
  - `mira:1` trigger → `{ plant_type = 3, count = 16, min_money = 75 }`
  - `dottie:2` trigger → `{ plant_type = 4, count = 11, min_money = 300 }`
  - `the_collector:1` trigger → `{ plant_type = 5, count = 13, min_money = 700 }`

- [x] Task C — `tests/test_customer_scripts.lua` — Add tests covering `min_money` gating (requires Task A done first):
  - chapter does NOT qualify when money is below `min_money` (use `mira:1` with `gs.currency = 74`)
  - chapter DOES qualify when money meets `min_money` (use `mira:1` with `gs.currency = 75`)
  - chapter with no `min_money` field is unaffected (existing behaviour, sanity check with `dottie:1` which has no `min_money`)
