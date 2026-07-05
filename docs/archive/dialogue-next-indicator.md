## Dialogue Next Indicator Checklist

- [x] Task A — `lua/game/customer.lua` — In `Customer:draw_bubble()`, after the text-rendering loop in the `else` branch, add logic to draw a scaled-down `A.arrow_right` (16×16) in the bottom-right corner of the bubble when `line_complete()` is true and more messages remain (check `after_msg_index < #after_messages` for `talking_after` state, otherwise `msg_index < #messages`).
