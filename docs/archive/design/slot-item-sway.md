# Slot Item Sway

## Goal

All items sitting in store slots sway gently in unison, like they're rocking in a breeze.
Plants that are ready to be watered (thirsty) are visually "still" — no sway — as a subtle
cue that something needs attention.

## Affected files

- `lua/game/slot.lua` — wrap `item:draw()` with `Sway.apply/clear`
- `lua/game/store.lua` — thread `sway_time` through to `slot:draw()`
- `lua/game/scenes/store_scene.lua` — set `gs.store.sway_time` each draw

## What changes

### How sway_time reaches slots

`StoreScene` already tracks `self._sway_time` (accumulated `dt`). Before calling
`self.drawer:draw()`, it writes this value onto the store:

```lua
gs.store.sway_time = self._sway_time
```

`Store:draw()` passes it through to each slot:

```lua
slot:draw(self.sway_time)
```

`Slot:draw(sway_time)` wraps `item:draw()` with the shader when conditions are met:

```lua
if sway_time and not (item.ready == true) then
    Sway.apply(sway_time, ITEM_SWAY_AMPLITUDE)
end
item:draw()
if sway_time and not (item.ready == true) then
    Sway.clear()
end
```

### Amplitude

The parallax layers use `0.004` (mid) and `0.007` (near). Slot items are smaller and
foreground objects, so a smaller amplitude is appropriate. `0.004` is a reasonable
starting point — easy to tune in `slot.lua` as a local constant `ITEM_SWAY_AMPLITUDE`.

### Thirsty plants stay still

A plant has `ready = true` when its cooldown has elapsed and it's waiting to be watered.
That state already drives the bubble visibility. The sway skip piggybacks on the same flag.
Non-plant items (Watering Can, Garbage Bin, PC Store, Grafter) never have `ready` set, so
they always sway.

### Unison

Because all slots read from the same `store.sway_time` (a single accumulator), every item
shares the same phase — they sway together.

## What stays the same

- The Sway shader itself (`assets/shaders/sway.glsl`, `lua/game/shaders/sway.lua`) is
  unchanged.
- Parallax layer sway in `StoreScene:draw()` is unchanged.
- `Store:draw_bg()` is unchanged.
- The `Drawer` interface (`draw()` with no args) is unchanged — `Store` is still registered
  at priority 0; the sway_time is set on the store object before the drawer runs.
- Item `draw()` methods are unchanged; the shader wrap lives entirely in `Slot:draw()`.

## Open questions

None — scope is clear.
