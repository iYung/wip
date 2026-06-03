## Speech Bubble Fix Checklist

- [x] Task A — `lua/game/customer.lua` — Remove the `name .. ": "` prefix from all dialogue text. Three sites: `make_full_text` (line 41–43), `serve` (line 170), and `advance_after` (line 188). Each should use the raw message string only.

- [x] Task B — `lua/game/customer.lua` — Add `MAX_BOX_W = 18 * U` (360px) constant near the top with the other size constants. In `draw_bubble`'s else-branch (the text bubble path), replace the single-line width calculation with `font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` to get wrapped lines. Size `box_w` to the widest wrapped line (capped at `MAX_BOX_W`), size `box_h` to fit all lines (`text_h * #lines + PAD * 2`). Apply the same wrapping to the revealed substring for the typewriter animation. Render each line individually with `love.graphics.print`.
