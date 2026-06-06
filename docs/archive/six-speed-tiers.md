## Six Speed Tiers Checklist

- [x] Task A — `lua/game/data/speed_tiers.lua` — Replace the 3-tier table with 6 tiers. Keep tier [0] unchanged. Update tiers [1]–[3] and add [4]–[6] with new speeds, costs, primary colors, and a `secondary` field (dark brown `{0.3, 0.15, 0.05, 1}`) on every tier. Values:
  - [1] cost=15,  speed=320,  color={0.1, 0.4,  1.0,  1}, secondary={0.3, 0.15, 0.05, 1}
  - [2] cost=30,  speed=450,  color={0.4, 0.1,  0.9,  1}, secondary={0.3, 0.15, 0.05, 1}
  - [3] cost=55,  speed=590,  color={0.7, 0.1,  0.8,  1}, secondary={0.3, 0.15, 0.05, 1}
  - [4] cost=100, speed=720,  color={1.0, 0.1,  0.6,  1}, secondary={0.3, 0.15, 0.05, 1}
  - [5] cost=200, speed=960,  color={1.0, 0.3,  0.1,  1}, secondary={0.3, 0.15, 0.05, 1}
  - [6] cost=360, speed=1200, color={1.0, 0.05, 0.05, 1}, secondary={0.3, 0.15, 0.05, 1}

- [x] Task B — `lua/game/player.lua` — Update `set_speed_color` to accept and store a secondary color (`self._speed_secondary`). Update `draw` to call `ColorReplace.apply(self._speed_color, self._speed_secondary)` instead of the current single-arg call. Initialize `self._speed_secondary` to `nil` in `Player.new`.

- [x] Task C — `lua/game/scenes/buy_scene.lua` — In the speed_boost preview block (around line 303), update `ColorReplace.apply(next_tier.color)` to `ColorReplace.apply(next_tier.color, next_tier.secondary)` so the buy-scene preview shows the dark brown secondary. Also update the `_confirm` handler's `gs.player:set_speed_color(tier.color)` call to also pass `tier.secondary` (requires the updated signature from Task B).

- [x] Task D — `tests/test_balance.lua` — Update the hardcoded `speeds` and `speed_costs` local tables (around lines 296–297) to reflect all 6 tiers:
  - speeds:      `{ [0]=220, [1]=320, [2]=450, [3]=590, [4]=720, [5]=960, [6]=1200 }`
  - speed_costs: `{ [1]=15, [2]=30, [3]=55, [4]=100, [5]=200, [6]=360 }`
  - Update any loop bounds or print format strings that assumed exactly 3 speed tiers.
