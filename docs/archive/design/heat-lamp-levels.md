# Heat Lamp Levels Expansion

## Goal

Expand the Heat Lamps upgrade from 3 purchasable tiers to 6, keeping the same start value (1.25×) and raising the ceiling to 3.00× (50% above the current 2.00× max). Tiers are evenly distributed across the full range.

## Affected files

- `lua/game/data/growth_tiers.lua` — replace 3-tier table with 6-tier table
- `lua/game/assets.lua` — extend heat_lamps loader from `1..3` to `1..6`
- `tests/test_shop.lua` — update growth_mult assertion for tier 1 (unchanged at 1.25), add coverage for new tiers and max-level guard
- `tests/test_save.lua` — update any hardcoded tier counts/values if needed

## What changes

### `lua/game/data/growth_tiers.lua`

Replace the 3-entry table with 6 entries. Multipliers are evenly spaced from 1.25 to 3.00 (step 0.35):

| Tier | mult | cost |
|------|------|------|
| 1    | 1.25 | 20   |
| 2    | 1.60 | 50   |
| 3    | 1.95 | 100  |
| 4    | 2.30 | 200  |
| 5    | 2.65 | 350  |
| 6    | 3.00 | 500  |

Tiers 1 and 2 keep their existing mult values exactly; tier 3 shifts from 2.00 → 1.95.

### `lua/game/assets.lua`

Change the loop bound from `1, 3` to `1, 6` so it loads `heat_lamp_4.png`, `heat_lamp_5.png`, `heat_lamp_6.png` via `try_img` (graceful if files aren't dropped in yet). The user will supply the three new PNGs.

### Tests

`test_shop.lua` asserts `growth_mult == 1.25` after buying tier 1 — this stays correct. The test for max-level guard (`gs.growth_level >= #GROWTH_TIERS`) will now trigger at 6 instead of 3; update any hardcoded numeric comparisons.

`test_save.lua` uses `growth_mult = 1.6` for a round-trip test — this is still a valid value (tier 2), so no change needed.

## What stays the same

- `buy_scene.lua` — all logic reads `#GROWTH_TIERS` dynamically; no changes needed
- `store_scene.lua` — renders `heat_lamps[growth_level]`; already nil-safe for missing assets, so levels 4–6 will display correctly once PNGs are added
- `GameState` fields (`growth_level`, `growth_mult`) — no schema changes; save format is unaffected
- All other upgrades (speed, cooldown, drone)

## Open questions

None — resolved before writing this doc.
- Costs for tiers 4/5/6: 200 / 350 / 500
- Sprites for levels 4–6: user will supply `heat_lamp_4/5/6.png`; code loads via `try_img` (no crash if absent)
