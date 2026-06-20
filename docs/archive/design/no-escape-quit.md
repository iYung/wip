## Goal

Remove the ability for the Escape key and the controller Start button to directly quit the game. Quitting should only happen through explicit menu choices ("Leave Game" in SettingsMenu, "Exit" in StartScene's own menu).

## Affected files

- `main.lua` — `love.keypressed` and `love.gamepadpressed` handlers

## What changes

**`love.keypressed` (main.lua ~line 208):**

Currently: if Escape is pressed and the current scene does NOT have `esc_opens_settings`, and the settings menu isn't open, `love.event.quit()` is called.

After: remove that `love.event.quit()` call entirely. Escape does nothing when no scene claims it for settings.

**`love.gamepadpressed` (main.lua ~line 231):**

Currently: if Start is pressed and the current scene does NOT have `esc_opens_settings`, `love.event.quit()` is called.

After: remove that `love.event.quit()` call entirely. Start does nothing when no scene claims it.

## What stays the same

- `SettingsMenu` item 7 "Leave Game" still calls `love.event.quit()` — intentional, explicit user action.
- `StartScene` "Exit" option (item 4) still calls `love.event.quit()` — intentional, explicit user action.
- Escape still opens/closes SettingsMenu when the current scene has `esc_opens_settings = true` (StoreScene, BuyScene).
- Start button still opens SettingsMenu when the current scene has `esc_opens_settings = true`.
- Escape still closes SettingsMenu from within the menu (via `SettingsMenu:update` and `SettingsMenu:gamepadpressed`).

## Open questions

None.
