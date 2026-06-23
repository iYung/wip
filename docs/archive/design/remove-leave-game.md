## Goal

Remove the "Leave Game" button from the settings menu when opened from the start scene (`opaque=true`). Keep "Main Menu" (item 7) visible when opened in-game (`opaque=false`).

## Affected files

- `lua/game/scenes/settings_menu.lua` — filter item 7 in `_visible_items`
- `tests/test_settings_menu.lua` — update tests that assume item 7 is visible when opaque

## What changes

### `lua/game/scenes/settings_menu.lua`

In `_visible_items(opaque, mode)`, add a condition to exclude item 7 when `opaque=true`:

```lua
if not (opaque and i == 7) then
    -- include item
end
```

No other code changes needed — `_confirm()`, `_on_leave`, and the draw label logic are all correct as-is.

### `tests/test_settings_menu.lua`

- Update navigation wrap tests that assume 7 visible items when `opaque=true`:
  - "up from 1 wraps to 7" → now wraps to 6 when opaque
  - "7 downs from 1 wraps back to 1" → now 6 downs when opaque
- **Test 15** ("Leave Game calls quit") opens without opaque so item 7 is still reachable; test remains valid as-is

## What stays the same

- In-game settings (`opaque=false`): item 7 shows "Main Menu" and works exactly as before
- Start-screen settings (`opaque=true`): items 1–6 visible; "Leave Game" hidden
- `_on_leave`, `main.lua`, `_confirm()`, draw — no changes

## Open questions

None.
