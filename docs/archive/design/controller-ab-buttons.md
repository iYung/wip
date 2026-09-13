# Controller A/B Buttons

## Goal

Change the gamepad layout from A/Y to A/B. `interact` stays on A; `pick_up_down` moves from Y to B, with Y dropped entirely.

## Affected files

- `lua/core/input.lua` — pad labels, icon keys, and gamepad read logic

## What changes

| | Before | After |
|---|---|---|
| `pick_up_down` gamepad read | `joy:isGamepadDown("y") or joy:isGamepadDown("b")` | `joy:isGamepadDown("b")` |
| `_PAD_LABELS.pick_up_down` | `"[Y]"` | `"[B]"` |
| `_PAD_ICON_KEYS.pick_up_down` | `"btn_y"` | `"btn_b"` |

`btn_b.png` already exists in `assets/images/` and is loaded in `assets.lua`.

## What stays the same

- `interact` stays on A (`joy:isGamepadDown("a")`, label `[A]`, icon `btn_a`)
- All keyboard bindings unchanged
- All callers of `key_for` / `icon_key_for` unchanged — they get the new label/icon automatically
- `btn_y.png` asset stays in place (not used by gameplay after this change, but no reason to delete it)

## Open questions

None — Y is dropped entirely, not kept as a fallback.
