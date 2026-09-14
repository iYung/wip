# Fix: Customer One-Frame Flash on Spawn

## Goal

Prevent customers from flashing for one frame at their previous idle position when a new customer walks in.

## Affected files

- `lua/game/customer.lua`

## What changes

`Customer:show()` currently sets `sprite.visible = true` and resets `self.x = self.exit_x`, but does **not** update `sprite.x` / `sprite.y`. Those positions are only synced in `Customer:update()`. On the first frame after `show()` is called, the draw happens before the next `update()` runs, so the sprite renders at whatever x/y it held from the previous customer's last `update()` — which is typically near `target_x` (the waiting position, by the first store slot). This causes a one-frame flash at that stale location.

**Fix:** At the end of `Customer:show()`, immediately sync `sprite.x` and `sprite.y` to match the new `self.x` / `self.y` (exit position, off-screen). This is the same arithmetic already used in `update()`:

```lua
self.sprite.x = self.x - CW / 2
self.sprite.y = self.y - CH / 2 - 20
```

Bubble and heart-bubble positions don't need syncing here because both are set invisible in `show()` and are only drawn when visible, so their stale positions cause no visible artifact.

## What stays the same

- `Customer:update()` logic is unchanged.
- Customer walking, dialogue, and serve/dismiss flows are unchanged.
- No changes to `store_scene.lua` or any other file.

## Open questions

None — root cause and fix are unambiguous.
