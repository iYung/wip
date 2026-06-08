# Dialogue Wrap Flicker Fix

## Goal

Eliminate the visual flicker that occurs during the typewriter-reveal effect when dialogue text approaches the maximum box width and then jumps to the next line.

## Root Cause

In `lua/game/customer.lua:draw_bubble()` (line 336), the revealed text is re-wrapped each frame:

```lua
local _, revealed_lines = font:getWrap(revealed, MAX_BOX_W - PAD * 2)
```

`font:getWrap` only wraps at **word boundaries**. While a word is still being revealed character by character, the partial word is not yet long enough to trigger wrapping — so it stays on line 1 and extends up to (or past) the full box width. On the frame where enough characters have been revealed to push the next word over the limit, the line suddenly wraps. This causes a one-frame flash where the text is wider than its final wrapped form.

The box dimensions (`box_w`, `box_h`) are already correctly computed from the **full text** on line 325 and are stable — the flicker is purely a rendering artifact from re-wrapping the partial revealed string.

## What Changes

Replace the `font:getWrap(revealed, ...)` call with a method that uses the pre-computed full-text line breaks. Instead of re-wrapping the revealed substring, we iterate through the canonical `lines` (computed from the full text) and reveal only as many bytes of each line as `reveal_index` allows.

Algorithm:

```
rendered_lines = []
remaining_bytes = reveal_index

for each line in lines (full-text wrap):
    if remaining_bytes <= 0: break
    visible = min(remaining_bytes, len(line))
    append line[0..visible] to rendered_lines
    remaining_bytes -= len(line) + 1   -- +1 for the space/newline getWrap consumed
```

The `+1` accounts for the whitespace character that `getWrap` consumed when wrapping the line (it is present in `_full_text` but stripped from the end of each `lines` entry). This keeps the byte offset in sync with `_full_text`.

Edge cases:
- Last line: `remaining_bytes` will go negative after it — the loop exits naturally.
- Explicit `\n` in dialogue text: `getWrap` treats these as hard breaks; the consumed character is still 1 byte (`\n`), so the `+1` holds.
- Words longer than wrap width: extremely unlikely in dialogue text; acceptable to leave as a known edge case.

## What Stays the Same

- `box_w` and `box_h` calculation (still based on full text).
- `font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` on line 325 is still needed for sizing.
- `reveal_index` tracking, clamping, UTF-8 boundary logic — unchanged.
- All other drawing code (9-slice bubble, tail, color) — unchanged.

## Affected Files

- `lua/game/customer.lua` — `draw_bubble()` only

## Open Questions

None. Cause is identified, fix is straightforward.
