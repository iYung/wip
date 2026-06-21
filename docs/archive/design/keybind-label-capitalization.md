## Goal
Capitalize the first letter of each action label in the keybinds sub-screen so they read "Up", "Down", "Left", "Right", "Interact" instead of "up", "down", "left", "right", "interact".

## Affected files
- `lua/game/scenes/settings_menu.lua`

## What changes
`_ACTION_LABELS` on line 15 is updated from lowercase strings to title-case:
```lua
-- before
local _ACTION_LABELS = {"up","down","left","right","interact"}
-- after
local _ACTION_LABELS = {"Up","Down","Left","Right","Interact"}
```

## What stays the same
- The bound key values displayed on the right side already use `:upper()` — no change needed there.
- All logic, layout, and other strings are untouched.

## Open questions
None.
