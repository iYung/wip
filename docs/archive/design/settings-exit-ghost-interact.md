## Goal

Prevent the interact action from firing in `StoreScene` immediately after the player closes `SettingsMenu` using the interact/confirm key.

## Affected files

- `main.lua` — where `love.update` decides whether to call `input:update()` vs `settings_menu:update(dt)`

## What changes

### Root cause

While `SettingsMenu` is open, `main.lua` skips `input:update()`:

```lua
if settings_menu and settings_menu.is_open then
    settings_menu:update(dt)          -- only this runs; input:update() is NOT called
else
    input:update()
    scene_manager:update(dt)
end
```

`input._down` therefore freezes at the state from the last frame before settings opened. When the player presses Space to confirm "Exit Settings", `settings_menu:update()` detects the press via `love.keyboard.isDown` internally and calls `self:close()`. That same frame, the scene still doesn't update (settings was open at the start of the frame).

Next frame, settings is now closed → `input:update()` runs. If Space is still physically held (or just barely released), it finds `_down["interact"] == false` (never updated while settings was open) and `love.keyboard.isDown("space") == true` → marks it as a fresh press. `StoreScene:update()` then sees `input:pressed("interact")` as `true` and fires an interact on whatever the player is hovering.

### Fix

In `main.lua`'s `love.update`, after `settings_menu:update(dt)` runs, detect whether settings just closed that frame and prime `input` with the current keyboard state:

```lua
if settings_menu and settings_menu.is_open then
    settings_menu:update(dt)
    if not settings_menu.is_open then
        -- Settings closed this frame. Prime _down so the key that triggered
        -- the close doesn't register as a fresh press in the scene next frame.
        input:update()
    end
else
    input:update()
    scene_manager:update(dt)
end
```

Calling `input:update()` here sets `_down["interact"] = true` (Space is still held) without advancing the scene. Next frame's `input:update()` then sees the key as already-down and won't mark it as a new press.

Note: the existing `_on_leave` callback already calls `input:update()` for the "Main Menu" exit path; this fix covers the "Exit Settings" (stay in store) path that was missed. When `_on_leave` fires, `input:update()` will be called twice in the same frame — once from this new check, once from `_on_leave`. The second call is idempotent: `_down` is already current, so `_pressed` ends up empty, which is correct.

## What stays the same

- `SettingsMenu` internals — no changes to the menu itself
- The `SettingsMenu:open()` snapshot logic (prevents keys held at *open* time from firing) — already correct
- `_on_leave` input priming — already correct, not touched

## Open questions

None — the cause and the minimal fix are unambiguous.
