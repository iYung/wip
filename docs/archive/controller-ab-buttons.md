# Controller A/B Buttons Checklist

- [x] Task A — `lua/core/input.lua` — change `pick_up_down` gamepad read from `joy:isGamepadDown("y") or joy:isGamepadDown("b")` to `joy:isGamepadDown("b")` only; update `_PAD_LABELS.pick_up_down` from `"[Y]"` to `"[B]"`; update `_PAD_ICON_KEYS.pick_up_down` from `"btn_y"` to `"btn_b"`
