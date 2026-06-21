# Web Gamepad Simulation

## Goal

Add a toggle to the web preview controls bar that switches between keyboard mode (current buttons) and gamepad mode (simulated controller buttons). This lets testers verify gamepad-specific UI (button icons in HUD, hidden Keybinds option in Settings, etc.) without a physical controller.

## Affected files

- `web/controls.js` — all changes live here
- `web-template/controls.js` — mirror the same changes so future builds pick them up

## What changes

### Technical approach — fake Gamepad via `navigator.getGamepads` override

The browser Gamepad API is read-only; you cannot dispatch synthetic gamepad events. However, Emscripten's SDL layer polls `navigator.getGamepads()` every frame to read axis and button state. We override that function with one that returns a fake `Gamepad` object whose button/axis state we control from JS.

Steps:
1. **Before** Love2D WASM initialises, inject a fake gamepad into `navigator.getGamepads`.
2. Expose a `window.__fakeGamepad` object with `buttons[]` (each `{pressed, value}`) and `axes[]`.
3. Fire a `gamepadconnected` DOM event so Emscripten registers the device and calls `love.joystickadded`.
4. Web UI buttons set `pressed`/`value` on the fake gamepad for the duration of the touch/click.
5. On release, reset those fields so the game sees a clean button-up on the next poll.

### Fake gamepad button index mapping

Standard Gamepad API indices (same as Emscripten uses for SDL mapping):

| Index | SDL name  | Game action     | Web UI label |
|-------|-----------|-----------------|--------------|
| 0     | `a`       | interact        | A            |
| 1     | `b`       | cancel          | B            |
| 3     | `y`       | pick_up_down    | Y            |
| 9     | `start`   | settings (menu) | Start        |
| 12    | `dpup`    | move up         | ↑            |
| 13    | `dpdown`  | move down       | ↓            |
| 14    | `dpleft`  | move left       | ←            |
| 15    | `dpright` | move right      | →            |

Axes 0 and 1 (left stick) stay at 0 — D-pad buttons are sufficient for all in-game movement.

### Mode toggle

A small toggle button appears in the centre of the controls bar between the two clusters. Label: `⌨` (keyboard mode) or `🎮` (gamepad mode). Clicking it:
- Swaps which cluster set is rendered (keyboard vs gamepad buttons).
- In keyboard → gamepad transition: fires `gamepadconnected` so Love2D registers the device.
- In gamepad → keyboard transition: fires `gamepaddisconnected` so Love2D switches back.

### Button layout — gamepad cluster (replaces keyboard clusters when active)

Left cluster (D-pad, same grid as current keyboard left cluster):
- ↑ → dpup (index 12)
- ← → dpleft (index 14)
- ↓ → dpdown (index 13)
- → → dpright (index 15)

Right cluster (face buttons, 2×2 grid):
- A (index 0) top-left
- B (index 1) top-right
- Y (index 3) bottom-left
- Start (index 9) bottom-right

### `gamepadconnected` / `gamepaddisconnected` events

```js
// Connect
window.__fakeGamepad.connected = true;
window.dispatchEvent(new GamepadEvent('gamepadconnected', { gamepad: window.__fakeGamepad }));

// Disconnect
window.__fakeGamepad.connected = false;
window.dispatchEvent(new GamepadEvent('gamepaddisconnected', { gamepad: window.__fakeGamepad }));
```

Emscripten listens to these window events to add/remove joystick objects on the Lua side.

## What stays the same

- Keyboard simulation buttons and all their existing behaviour are unchanged.
- `fireKey` / `attachButton` / `KEY_CODES` are untouched.
- Canvas scaling logic is untouched.
- No Lua code changes required — Love2D sees a real (fake) gamepad through the normal API.

## Open questions

None — user confirmed: all game-mapped buttons, toggle-based layout replacement.
