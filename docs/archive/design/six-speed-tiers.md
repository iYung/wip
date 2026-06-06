## Goal

Expand move speed from 3 purchasable tiers to 6. Tiers 1-4 cover the same speed range as the current 1-3 (320–720), evenly spread with one extra step. Tiers 5 and 6 are new, faster upgrades beyond 720.

Primary shoe color graduates from blue → red across all 6 tiers. The secondary color (sole/accent pixels in the sprite) is always dark brown.

## Affected files

- `lua/game/data/speed_tiers.lua` — add tiers 4, 5, 6; update all tier colors (blue→red); add `secondary` field (dark brown) to each tier
- `lua/game/player.lua` — update `set_speed_color` and `draw` to store and pass secondary color to `ColorReplace.apply`
- `lua/game/scenes/buy_scene.lua` — update speed_boost preview to pass secondary color to `ColorReplace.apply`
- `tests/test_balance.lua` — hardcoded `speeds` and `speed_costs` tables reference the old 3-tier values
- `tests/test_shop.lua` — tier-1 speed/cost/color tests remain valid; max-level check uses `#SPEED_TIERS` dynamically so it auto-updates

## What changes

### Speed tier table (`speed_tiers.lua`)

| Tier | Speed | Cost | Primary color | Secondary |
|------|-------|------|---------------|-----------|
| 0    | —     | —    | white (base)  | — |
| 1    | 320   | $15  | blue `{0.1, 0.4, 1.0}` | dark brown `{0.3, 0.15, 0.05}` |
| 2    | 450   | $30  | blue-purple `{0.4, 0.1, 0.9}` | dark brown |
| 3    | 590   | $55  | purple `{0.7, 0.1, 0.8}` | dark brown |
| 4    | 720   | $100 | magenta `{1.0, 0.1, 0.6}` | dark brown |
| 5    | 960   | $200 | orange-red `{1.0, 0.3, 0.1}` | dark brown |
| 6    | 1200  | $360 | deep red `{1.0, 0.05, 0.05}` | dark brown |

Tiers 1 and 4 anchor the original speed endpoints (320 and 720). Tiers 5 and 6 continue at roughly ×1.33 and ×1.67 of tier 4.

### `player.lua`

`set_speed_color` stores both primary and secondary. `draw` passes both to `ColorReplace.apply(primary, secondary)`.

### `buy_scene.lua`

The speed_boost preview already calls `ColorReplace.apply(next_tier.color)` — update to also pass `next_tier.secondary` so the buy-scene preview matches the in-game player appearance.

### Tests

`test_balance.lua` has hardcoded `speeds` and `speed_costs` local tables (lines ~296–297) that mirror the old 3-tier values — update them to reflect all 6 tiers.

`test_shop.lua` existing tests remain valid: tier-1 speed/cost values are unchanged; color test references `SPEED_TIERS[1].color` which still exists.

## What stays the same

- `color_replace.glsl` shader — no changes; it already handles `replace_color_a` (primary) and `replace_color_b` (secondary)
- `game_state.lua` — no changes; save/load logic is tier-count-agnostic
- All other systems (growth tiers, cooldown tiers, drone, store) — untouched

## Open questions

**Save compatibility:** Existing saves with `speed_level=2` (old orange, speed 480) will load as new tier 2 (blue-purple, speed 450) — minor speed decrease and color change. No migration planned; the game is in development.
