## Heat Lamp Levels Checklist

- [x] Task A — `lua/game/data/growth_tiers.lua` — Replace the 3-entry table with 6 entries: `{cost=20, mult=1.25}`, `{cost=50, mult=1.60}`, `{cost=100, mult=1.95}`, `{cost=200, mult=2.30}`, `{cost=350, mult=2.65}`, `{cost=500, mult=3.00}`

- [x] Task B — `lua/game/assets.lua` — Change the heat_lamps loop bound from `1, 3` to `1, 6` so levels 4–6 are loaded via `try_img`

- [x] Task C — `tests/test_shop.lua` — Update the test that asserts growth_mult after buying tier 1 (should still be 1.25 — verify it passes), and update any assertions that compare against the old max level of 3 (should now be 6)

- [x] Task D — `tests/test_save.lua` — Audit for any hardcoded growth tier counts or mult values that assumed 3 tiers; update if needed (note: the `growth_mult = 1.6` round-trip test remains valid as tier 2 is unchanged)
