# Speech Bubble Fix

## Goal

Fix two related speech bubble problems:
1. Customer name prefix (`"Old Pete: "`) is prepended to every line of dialogue, making lines longer than necessary and visually noisy.
2. Bubble width is sized to the raw text width with no wrapping, so long lines extend off-screen.

## Affected files

- `lua/game/customer.lua` — all changes live here

## What changes

### 1. Remove name prefix from dialogue text

`make_full_text` (line 41–43) builds `c.name .. ": " .. message`. This prefix is also hardcoded in `serve()` (line 170) and `advance_after()` (line 188). All three sites should drop the name and just use the raw message string.

### 2. Wrap long lines inside the bubble

The `draw_bubble` else-branch (lines 304–331) currently:
- Measures `text_w = font:getWidth(self._full_text)` (single-line width)
- Sets `box_w = math.max(MIN_BOX_W, text_w + PAD * 2)` — no cap, so long text overflows the screen

Fix: introduce a `MAX_BOX_W = 18 * U` constant (360px). Use `font:getWrap(text, MAX_BOX_W - PAD * 2)` to split the text into wrapped lines, size the box to the widest wrapped line (capped at `MAX_BOX_W`) and tall enough for all lines, and render each line individually.

The reveal animation currently slices `_full_text` by byte index. After wrapping, the visible portion should still be sliced the same way from the full unwrapped string; only the draw call changes to word-wrap the revealed substring.

## What stays the same

- The plant-image bubble shown when `done_talking` is true (the "show me this plant" state) — no name prefix there, no wrapping needed.
- `heart_bubble` drawing.
- All customer state machine logic, timing, and animation.
- `customer_scripts.lua` message strings — no changes needed there.
- Tests for customer scripts.

## Open questions

None — requirements are clear. Proceeding to checklist.
