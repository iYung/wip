## Goal

Fix a bug where, if the garbage bin happens to occupy the leftmost shop slot
(slot 1), the player can discard a held item while standing in the cashier
zone (talking to / serving a customer). Discarding should only be possible in
the main shop area, never in the cashier zone.

## Affected files

- `lua/game/scenes/store_scene.lua` — `StoreScene:_handle_interact`, the
  discard check at line 409
- `tests/test_customer_scripts.lua` (or wherever interact/discard behavior is
  tested) — add regression coverage

## What changes

- The discard branch in `StoreScene:_handle_interact` (around
  `store_scene.lua:409`) gains a `player.x >= 0` guard, matching the existing
  cashier-zone guards on lines 372 and 377 (`player.x < 0`). This ensures
  discarding only triggers in the main shop area.

### Root cause

`Store:slot_at(x)` (`lua/game/store.lua:26-29`) clamps its computed index to
`[1, #self.slots]`:

```lua
function Store:slot_at(x)
    local idx = math.floor(x / self.slot_width) + 1
    idx = math.max(1, math.min(#self.slots, idx))
    return self.slots[idx]
end
```

For any `x < 0` (i.e. anywhere in the cashier zone), `math.floor(x / slot_width) + 1`
evaluates to `0`, which the `math.max(1, ...)` clamps to `1`. So
`active_slot()` always reports **slot 1** while the player is in the cashier
zone — this is intentional/harmless as a fallback for code that just needs
"some slot," but it means the discard check at line 409, which has no zone
guard, will fire if slot 1 happens to contain the garbage bin and the player
is standing in the cashier zone holding a sellable item.

## What stays the same

- `Store:slot_at` is unchanged — its clamping behavior is relied upon
  elsewhere and isn't itself wrong.
- The cashier-zone sale/dialog logic (lines 372-406) is unchanged.
- Discarding in the main shop area continues to work exactly as before,
  regardless of which slot the garbage bin occupies.

## Open questions

None — the fix is a one-line guard addition mirroring the existing pattern
used just above it in the same function.
