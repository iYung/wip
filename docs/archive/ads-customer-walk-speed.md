# Design: Ads Upgrade Also Affects Customer Walking Speed

## Goal

Each tier of the Marketing (Ads) upgrade should increase customer walking speed in addition to its existing effect of reducing spawn cooldown. Better ads attract more eager customers who walk faster.

## Current State

- Ads upgrade is defined in [lua/game/data/cooldown_tiers.lua](lua/game/data/cooldown_tiers.lua) with 3 tiers (costs $10/$25/$50), each reducing spawn cooldown.
- Customer walking speed is a hardcoded local constant `SPEED = 80` at [lua/game/customer.lua:14](lua/game/customer.lua#L14), used in both `walking_in` and `walking_out` states (lines 219, 226).
- Customers are spawned via `Customer:show(cfg)` ([customer.lua:105](lua/game/customer.lua#L105)); `cfg` is assembled in `store_scene.lua` and does not currently carry a speed value.
- `Customer` objects have no reference to `game_state`.

## What Changes

### 1. `lua/game/data/cooldown_tiers.lua`
Add a `walk_speed` field to each tier entry. Base walk speed (level 0, no upgrade) stays at 80.

```lua
-- proposed values (open question below)
{ cost = 10, cooldown = 3, walk_speed = 100, label = "Customers come faster" },
{ cost = 25, cooldown = 2, walk_speed = 120, label = "Customers come even faster" },
{ cost = 50, cooldown = 0, walk_speed = 150, label = "Customers come even even faster" },
```

### 2. `lua/game/customer.lua`
- Replace the hardcoded `local SPEED = 80` constant usage with `self.speed` instance field.
- Initialize `self.speed = 80` as the default in `Customer:show()`.
- Accept `cfg.walk_speed` in `Customer:show()`: `self.speed = cfg.walk_speed or 80`.
- Update movement lines 219 and 226 to use `self.speed` instead of `SPEED`.

### 3. `lua/game/scenes/store_scene.lua`
- Add a helper (analogous to `spawn_cooldown`) to look up walk speed from `gs.cooldown_level`:
  ```lua
  local function customer_walk_speed(gs)
      if gs.cooldown_level == 0 then return 80 end
      return COOLDOWN_TIERS[gs.cooldown_level].walk_speed
  end
  ```
- Pass `walk_speed = customer_walk_speed(gs)` into the `cfg` table when calling `self._customer:show(cfg)` (lines 234 and 239).

## What Stays the Same

- The ads upgrade's spawn cooldown behavior is unchanged.
- `gs.cooldown_level` integer — no new game-state fields needed.
- All other upgrade systems (speed/sneakers, growth/heat lamps) are untouched.
- `Customer:show()` signature is backwards-compatible; `cfg.walk_speed` is optional with an `or 80` fallback.

## Open Questions

1. **Walk speed values per tier** — proposed 80 → 100 → 120 → 150. Do these feel right, or should the jump be larger/smaller?
2. **Walk-out speed** — should customers walk *out* faster too, or only walk *in* faster? (Currently both directions use `SPEED`; simplest to apply to both.)
