# Buy Scene HUD Overlay

## Goal

Wrap the existing BuyScene bottom-left controls hint in the same 9-slice `draw_hud_box` panel that StoreScene uses, drawn **after** the CRT shader so it sits on top of the scanline effect. Key labels should be read from the live input map so they reflect rebinds.

## Affected files

- `lua/game/scenes/buy_scene.lua` — move hint rendering out of the canvas, wrap in `UI.draw_hud_box` after `CRT.clear()`

## What changes

Currently the hints are hardcoded strings drawn **inside** the canvas (pre-CRT):

```lua
local hints = { "A/D: CYCLE", "F: BUY", "E: CANCEL" }
local hint_y = 652
for _, hint in ipairs(hints) do
    love.graphics.print(hint, 56, hint_y)
    hint_y = hint_y - 20
end
```

Changes:

1. **Remove** the existing hints block from inside the canvas render.
2. **Require `UI`** at the top of `buy_scene.lua`.
3. **After `CRT.clear()`**, build hints from `self.input:key_for(action)` — same pattern StoreScene uses for `e_key`/`f_key`:
   ```lua
   local left_key  = (self.input:key_for("move_left")    or "a"):upper()
   local right_key = (self.input:key_for("move_right")   or "d"):upper()
   local f_key     = (self.input:key_for("interact")     or "f"):upper()
   local e_key     = (self.input:key_for("pick_up_down") or "e"):upper()
   local hints = {
       left_key .. "/" .. right_key .. ": CYCLE",
       f_key .. ": BUY",
       e_key .. ": CANCEL",
   }
   ```
4. Call `UI.draw_hud_box(hints, font_ui)` then print the label text inside the box using the same coordinate logic StoreScene uses.

## What stays the same

- Hint content is unchanged: cycle / buy / cancel.
- Currency display at top-left (56, 44) is untouched.
- All CRT canvas rendering — untouched.
- `StoreScene` and `UI` module are untouched.

## Open questions

None.
