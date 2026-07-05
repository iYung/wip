## Arrow Blink Phase Checklist

- [x] Task A — `lua/game/customer.lua` — Add `self._arrow_t = nil` to `Customer.new()`, reset it to `nil` in `show()`, `advance()`, `serve()`, and `advance_after()`, accumulate it in `update()` (set to `0` on the first frame `line_complete()` is true, increment by `dt` thereafter), and replace the blink formula in `draw_bubble()` with `(math.cos((self._arrow_t or 0) * 8) + 1) / 2` so the indicator always starts at full opacity.
