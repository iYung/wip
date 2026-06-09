# Design: Remove Arrow Keys / WASD-Only Controls

## Goal
Remove arrow keys from the default movement bindings so WASD is the only way to move. Update the web test UI to send WASD key events instead of arrow key events.

## Why
Arrow keys were kept as secondary bindings when WASD was added. Now that the keybind system is configurable and the web UI has on-screen buttons, arrow keys are redundant and may confuse players about what keys to rebind. WASD-only is cleaner.

## Affected Files

### `lua/game/input.lua`
The default key map lists two keys per movement action. Remove the arrow key from each:
- `move_up    = {"up", "w"}` → `move_up    = {"w"}`
- `move_down  = {"down", "s"}` → `move_down  = {"s"}`
- `move_left  = {"left", "a"}` → `move_left  = {"a"}`
- `move_right = {"right", "d"}` → `move_right = {"d"}`

### `web-template/controls.js`
The on-screen d-pad fires `ArrowUp/Down/Left/Right` events. Switch to WASD:
- `KEY_CODES`: replace `ArrowUp/Down/Left/Right` (38/40/37/39) with `w/s/a/d` (87/83/65/68)
- Button labels: `↑ ← ↓ →` → `W A S D`
- `attachButton` calls: replace `'ArrowUp'/'ArrowLeft'/'ArrowDown'/'ArrowRight'` with `'w'/'a'/'s'/'d'` and matching `KeyW/KeyA/KeyS/KeyD` codes

## What Stays the Same
- `lua/core/input.lua` — no change; it already supports any key string Love2D accepts
- `pick_up_down = {"e"}` and `interact = {"f"}` — unchanged
- CSS grid layout of the web UI buttons — only labels and dispatched keys change
- Keybind save/load system — it stores whatever keys are currently bound; removing arrow keys from defaults doesn't break saved configs (saved configs don't reference the defaults)

## Open Questions
None — scope is clear.
