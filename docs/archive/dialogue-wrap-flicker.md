## Dialogue Wrap Flicker Checklist

- [x] Fix revealed-text re-wrap in draw_bubble — `lua/game/customer.lua` — Replace the `font:getWrap(revealed, MAX_BOX_W - PAD * 2)` call (line 336) and its `revealed_lines` loop with a byte-offset walk over the pre-wrapped `lines` (already computed from `_full_text` on line 325). For each line in `lines`, reveal `min(remaining, #line)` bytes and subtract `#line + 1` from remaining (the +1 accounts for the space/newline getWrap consumed). Stop when remaining ≤ 0. This pins line breaks to the full-text wrap points and eliminates the flicker.
