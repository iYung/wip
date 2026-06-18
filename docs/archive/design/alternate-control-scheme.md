# Alternate Control Scheme

## Goal
Add a second control scheme where dedicated `pick_up` (O) and `put_down` (P) keys replace `move_up`/`move_down` for picking up and putting down items. The player toggles between the two schemes in Settings. In the alternate scheme, W/S do nothing.

## Affected files
- `lua/game/settings_state.lua` — new `control_scheme` field; add `pick_up`/`put_down` to `keybinds` with defaults O/P; persist both
- `lua/game/scenes/settings_menu.lua` — new "Control Scheme" menu item; keybinds sub-screen shows scheme-appropriate action rows
- `lua/game/scenes/store_scene.lua` — `update()` and `_hud_labels()` branch on the active scheme
- `lua/game/input.lua` — add `pick_up`/`put_down` to the default key map

## What changes

### SettingsState
- New field `self.control_scheme = "up_down"` (default) or `"pick_put"` (alternate)
- `self.keybinds` gains `pick_up = "o"` and `put_down = "p"`
- `to_save()` includes `control_scheme`
- `from_save()` restores `control_scheme`; `pick_up`/`put_down` load from save or keep defaults for old saves

### SettingsMenu
- No new top-level menu item; control scheme lives inside the keybinds sub-screen
- The keybinds sub-screen gains a "Control Scheme" toggle row at the top (before the bindable key rows)
  - Displays the current scheme: "Up / Down" or "Pick Up / Put Down"
  - Confirming it toggles `settings_state.control_scheme` and updates `input._map` from the new key map
- The five bindable key rows below the toggle change per scheme:
  - `"up_down"`: Up, Down, Left, Right, Interact (existing behaviour)
  - `"pick_put"`: Pick Up, Put Down, Left, Right, Interact
- `_all_bound` check covers whichever 5 actions are currently shown
- "Return" button remains at the bottom; sub-screen navigation wraps across all rows (toggle + 5 key rows + Return)

### StoreScene
- `update()`: in `"pick_put"` mode, listen for `input:pressed("pick_up")` / `input:pressed("put_down")` instead of `move_up`/`move_down`; W/S do nothing (no dismiss either)
- `_handle_pick_up()` and `_handle_put_down()` are unchanged in logic; only the triggering action changes
- `_hud_labels()`: uses `pick_up`/`put_down` key labels when in `"pick_put"` mode; W/S dismiss label is hidden

### input.lua
- Add `pick_up = {"o"}` and `put_down = {"p"}` so the key map is fully populated before settings load

## What stays the same
- `_handle_pick_up()` and `_handle_put_down()` logic is identical in both schemes
- `interact` (Space) is the same in both schemes
- Left/Right movement is the same in both schemes
- Save/load format is backwards-compatible — old saves default to `"up_down"` scheme

## Open questions
None.
