## Goal

Show a small arrow in the bottom-right corner of speech bubbles when the current dialogue line is fully revealed and more lines remain. This gives the player a clear visual cue that pressing the interact key advances the conversation.

## Affected files

- `lua/game/customer.lua` — `Customer:draw_bubble()`

## What changes

A scaled-down `A.arrow_right` sprite is drawn inside the text bubble, anchored to the bottom-right corner (inset by `PAD`), whenever both conditions are true:

1. `self:line_complete()` — the typewriter reveal has finished.
2. There are more lines to show — `self.msg_index < #self.messages` during normal dialogue, or `self.after_msg_index < #self.after_messages` during `talking_after`.

The arrow is drawn at the end of the text-rendering block in the `else` branch of `draw_bubble()`, after all text is painted, so it always sits on top.

**Positioning:**
```
arrow_x = box_x + box_w - PAD - arrow_size
arrow_y = box_y + box_h - PAD - arrow_size
```

**Scale:** `A.arrow_right` is 60×60px. Draw at 16×16 (`scale = 16/60`).

**Visibility logic (within the else branch):**
```lua
local has_more
if self.state == "talking_after" then
    has_more = self.after_msg_index < #self.after_messages
else
    has_more = self.msg_index < #self.messages
end
local show_arrow = self:line_complete() and has_more
```

## What stays the same

- No new assets needed — `A.arrow_right` is already loaded.
- The existing HUD "NEXT" / "SKIP" labels in `store_scene.lua` are unchanged.
- The plant-image bubble shown after all messages are consumed (`done_talking and state ~= "talking_after"`) is unchanged.
- `after_messages` behaviour, typewriter timing, and all input handling are unchanged.

## Open questions

None — user confirmed: static PNG, only show after text finishes revealing.
