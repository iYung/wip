# Fix: Player Speed Not Applied on Load

## Goal

When a save file is loaded, the player's movement speed and speed color should reflect their purchased `speed_level`, not always start at the base speed of 220.

## Root Cause

`GameState.from_save()` ([lua/game/game_state.lua:99](lua/game/game_state.lua#L99)) correctly restores `self.speed_level` from the save data, but then creates a fresh `Player.new()` which always initializes `speed = 220` (BASE_SPEED) and `_speed_color = SPEED_TIERS[0].color`. Nothing ever applies the restored speed level to the new player object.

Contrast with the purchase path in `buy_scene.lua` (the `speed_boost` branch), which does apply both `gs.player.speed = tier.speed` and `gs.player:set_speed_color(tier.color)` at purchase time — that's why the shop display is correct but the actual speed isn't.

## Affected Files

| File | Change |
|------|--------|
| `lua/game/game_state.lua` | After creating the player in `from_save()`, apply the tier speed and color based on the restored `speed_level` |

## What Changes

In `GameState.from_save()`, after line 123 (where `player.held_item` is set), add code that:
1. Looks up `SPEED_TIERS[self.speed_level]`
2. If `speed_level > 0`, sets `self.player.speed = tier.speed` and `self.player:set_speed_color(tier.color)`

`SPEED_TIERS` is already imported in `player.lua` but not in `game_state.lua` — it needs to be required there too.

## What Stays the Same

- Save format is unchanged — `speed_level` is already saved and loaded correctly
- Purchase logic in `buy_scene.lua` is unchanged
- Player initialization defaults (`BASE_SPEED`, tier 0 color) are unchanged — they're correct for new games
- No other upgrade types (growth, cooldown) have a player-side runtime value to apply, so no parallel changes needed there

## Open Questions

None — the fix location and approach are unambiguous.
