## Goal

When a controller is active, replace the text button labels (`[A]`, `[B]`, `[Y]`) in the bottom-left HUD with small PNG icons — a plain colored circle with the letter — so the prompt looks immediately readable at a glance.

## Affected files

- `assets/images/btn_a.png` — new, generated (16×16 green circle with "A")
- `assets/images/btn_b.png` — new, generated (16×16 red circle with "B")
- `assets/images/btn_y.png` — new, generated (16×16 yellow circle with "Y")
- `lua/game/assets.lua` — load the three new PNGs
- `lua/core/input.lua` — add `_PAD_ICON_KEYS` table; add `Input:icon_key_for(action)`
- `lua/game/scenes/store_scene.lua` — change `_hud_labels()` return type; update draw loop
- `lua/game/ui.lua` — update `draw_hud_box` to accept structured `{icon, text}` entries

## What changes

### PNG icons
Three 16×16 PNGs generated with Python (Pillow): filled circle + white letter, one per button.
Colors: A = green `(80,160,80)`, B = red `(200,70,70)`, Y = yellow `(200,170,50)`.

### `lua/core/input.lua`
Add alongside `_PAD_LABELS`:
```lua
local _PAD_ICON_KEYS = {
    interact     = "btn_a",
    pick_up_down = "btn_y",
    cancel       = "btn_b",
}
```
Add method:
```lua
function Input:icon_key_for(action)
    if self._mode == "gamepad" then
        return _PAD_ICON_KEYS[action]
    end
end
```
`_PAD_LABELS` stays unchanged (arrow symbols / brackets still used as fallback and in tests).

### `lua/game/scenes/store_scene.lua` — `_hud_labels()`
Currently builds strings like `f_key .. ": SELL TO CUSTOMER"`.

New return type: each keyed entry becomes a table `{icon = "btn_a", text = ": SELL TO CUSTOMER"}` when in gamepad mode, or the raw string `"SPACE: SELL TO CUSTOMER"` when in keyboard mode. The slot label (no key) is always a plain string.

Helper inside `_hud_labels()`:
```lua
local function make_label(icon_key, key_text, action_text)
    if icon_key then
        return {icon = icon_key, text = ": " .. action_text}
    else
        return key_text .. ": " .. action_text
    end
end
```
`icon_key` comes from `self.input:icon_key_for(action)`.

The `labels` table therefore contains a mix of strings (slot) and `{icon, text}` tables (button prompts). The draw loop and `draw_hud_box` must handle both.

### `lua/game/ui.lua` — `draw_hud_box`
Width measurement must account for icons. Add a local helper `entry_width(entry, font, icon_size)`:
- plain string → `font:getWidth(entry)`
- table → `icon_size + font:getWidth(entry.text)`

`icon_size = 16`. Pass this through from the caller or hardcode it in `ui.lua` since it matches the PNG dimensions.

### `lua/game/scenes/store_scene.lua` — draw loop
```lua
local ICON_SIZE = 16
for _, entry in ipairs(labels) do
    if type(entry) == "table" and entry.icon then
        local icon_y = math.floor(y + (20 - ICON_SIZE) / 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(A[entry.icon], 10 + 14, icon_y)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(entry.text, 10 + 14 + ICON_SIZE + 2, y)
    else
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(entry, 10 + 14, y)
    end
    y = y + 20
end
```

## What stays the same

- `_PAD_LABELS` (used by `key_for`) — unchanged; keyboard mode is unaffected
- Arrow key labels (↑↓←→) — not shown in HUD, no change needed
- `UI.draw_hud_box` signature — still `(labels, font)`; the internal measurement changes
- `draw_currency_bubble` — untouched
- All tests that call `key_for` — unaffected
- BuyScene, SettingsMenu — they don't use `_hud_labels`, no change needed

## Open questions

None — user confirmed: generate neutral icons sized to match letter height (16×16 px).
