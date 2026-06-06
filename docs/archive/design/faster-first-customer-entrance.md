## Goal

On a brand new game, the first scripted customer (Sage / "Sir Moneyton", `sage:1`) doesn't start walking on screen until 4 seconds after the store scene loads (`spawn_cooldown` returns `4` when `cooldown_level == 0`). That feels like a long, dead wait before anything happens. We want this *first* wait to be much shorter — without changing the customer's walk speed, their off-screen spawn position, or the cooldown that governs every subsequent customer.

## Affected files

- `lua/game/scenes/store_scene.lua` — `_setup_store` (where `self._spawn_timer` is created) and `update` (where the timer fires and is reset back to the normal cooldown)
- `tests/test_customer_scripts.lua` and/or `tests/test_quest_timing.lua` — add/adjust coverage for the shortened first-spawn timer

## What changes

- In `StoreScene:_setup_store` (around `store_scene.lua:109`), when the scene is being set up for a brand new game (`not self._from_save`), the initial `self._spawn_timer` is created with a short interval (proposed: `1` second) instead of `spawn_cooldown(gs)` (which is `4`).
- The very first time the timer fires in `StoreScene:update` (around `store_scene.lua:311`, `self._spawn_timer:reset(cd)`), it is reset to the normal `spawn_cooldown(gs)` value as it already is today — so this only shortens the *one* initial wait, and every customer after that (including re-spawns of Sage if dismissed/re-triggered) follows the existing cooldown rules untouched.
- Loading from a save (`self._from_save == true`) is unaffected — it always uses the normal `spawn_cooldown(gs)` for the initial timer, exactly as today.

## What stays the same

- Walk speed (`customer_walk_speed`) — unchanged for every customer, including the first.
- Off-screen spawn position (`exit_x = -(ZONE_WIDTH + 200)`) and target position (`target_x = -ZONE_WIDTH / 2`) — unchanged. The character still walks the same distance at the same speed; only the *wait before they start* is shortened.
- The normal spawn cooldown (`spawn_cooldown(gs)`, cooldown tiers, etc.) for every subsequent customer spawn — unchanged.
- All scripted-customer trigger/dismiss/chapter logic in `customer_scripts.lua` — unchanged.

## Open questions

- None outstanding — confirmed with the user that only the spawn-timer wait should shrink (not the off-screen walk distance), and that this should apply only to brand new games, not saves where this scripted moment hasn't fired yet.
- The exact short interval (proposed `1` second) is a feel/pacing choice; the implementing task can tune it slightly if `1` feels off during manual testing, as long as it stays clearly shorter than the normal `4`-second cooldown.
