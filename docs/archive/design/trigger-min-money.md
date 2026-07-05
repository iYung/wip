## Goal

Add an optional `min_money` field to chapter trigger tables in `customer_scripts.lua`. When present, the chapter only qualifies to spawn if the player's current currency is also at or above that threshold (AND with the existing plant count gate). Apply the field to the first chapter, across all characters, that requests each new plant tier.

## Affected files

- `lua/game/data/customer_scripts.lua` — add `min_money` to five specific chapter triggers
- `lua/game/scenes/store_scene.lua` — `_next_customer_cfg()` trigger evaluation logic
- `tests/test_customer_scripts.lua` — new tests for min_money gating

## What changes

**Trigger evaluation in `store_scene.lua:_next_customer_cfg()`**

Currently:
```lua
if (gs.stage3_counts[t.plant_type] or 0) >= t.count then
```

After:
```lua
if (gs.stage3_counts[t.plant_type] or 0) >= t.count
    and (not t.min_money or gs.currency >= t.min_money) then
```

Both conditions must pass (AND). If `min_money` is absent (nil), the check is skipped and behavior is unchanged.

**Five chapter triggers in `customer_scripts.lua` get `min_money` added:**

| Chapter | Plant requested | Trigger before | Trigger after |
|---|---|---|---|
| `sage:2` | Cactus ($8) | `{ plant_type=1, count=3 }` | `{ plant_type=1, count=3, min_money=5 }` |
| `sage:4` | Rose ($20) | `{ plant_type=3, count=1 }` | `{ plant_type=3, count=1, min_money=20 }` |
| `mira:1` | Tulip ($75) | `{ plant_type=3, count=16 }` | `{ plant_type=3, count=16, min_money=75 }` |
| `dottie:2` | Daisy ($300) | `{ plant_type=4, count=11 }` | `{ plant_type=4, count=11, min_money=300 }` |
| `the_collector:1` | Lotus ($700) | `{ plant_type=5, count=13 }` | `{ plant_type=5, count=13, min_money=700 }` |

Thresholds equal the buy cost of one seedling of the newly requested plant — the minimum the player needs to actually grow one.

## What stays the same

- All other chapters (no `min_money`) behave identically.
- Plant count gate is still required; `min_money` adds to it, not replaces it.
- Chapter ordering (prior chapters must be seen) is unchanged.
- Cooldown, dismiss, seen_scripts, and no-repeat logic are unchanged.
- `currency` is read-only here — no change to how it is mutated.

## Open questions

None.
