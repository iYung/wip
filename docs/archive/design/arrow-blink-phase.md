## Goal

Fix the next-line indicator blink so it always starts at a known phase instead of jumping in mid-oscillation. Currently the oscillator uses `love.timer.getTime()` (global wall clock), so the indicator's alpha at the moment it appears is arbitrary — it can flash in at near-zero opacity and look like a glitch.

## Affected files

- `lua/game/customer.lua`

## What changes

Add `self._arrow_t` (number or nil) to `Customer` to track elapsed seconds since the current line's indicator last became visible.

**Reset to nil** whenever a new line starts (any place that resets `reveal_index` / `reveal_t`):
- `Customer.new()`
- `Customer:show()`
- `Customer:advance()`
- `Customer:serve()`
- `Customer:advance_after()`

**Accumulate in `update()`:** each frame, if `line_complete()` is true, initialise to `0` on the first such frame and increment by `dt` on subsequent frames.

**Use in `draw_bubble()`:** replace `love.timer.getTime()` with `self._arrow_t or 0` and switch from sine to cosine so the oscillator starts at full opacity:

```lua
local blink = (math.cos((self._arrow_t or 0) * 8) + 1) / 2
```

`cos(0) = 1` → indicator pops in at full opacity, then pulses down and back cleanly.

## What stays the same

- Blink speed (multiplier `8`), visual layout of the mini-bubble and arrow, all other `Customer` state.
- No new public API. `_arrow_t` is internal.

## Open questions

None.
