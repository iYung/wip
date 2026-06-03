# Scene Fade Transition

## Goal

Add a smooth black fade-out / fade-in when switching between scenes (Start → Store, Store → Buy, etc.) so the transition feels polished rather than a hard cut.

## Affected files

- `lua/core/scene_manager.lua` — owns the transition state and overlay draw
- `lua/game/config.lua` — add `LOGICAL_H = 720` so SceneManager can size the overlay

## What changes

### `config.lua`

Add `LOGICAL_H = 720` alongside the existing `LOGICAL_W = 1280`.

### `scene_manager.lua`

The manager gains a tiny state machine for the fade:

| State  | Meaning                                         |
|--------|-------------------------------------------------|
| `idle` | No transition in progress, scene renders normally |
| `out`  | Fading to black; current scene still ticking    |
| `in`   | Fading back from black; new scene already live  |

**New fields on SceneManager:**
- `_fade_state` — `"idle"` / `"out"` / `"in"`
- `_fade_alpha` — `0.0`–`1.0`, the opacity of the black overlay
- `_pending` — the scene object waiting to go live after the blackout
- `FADE_DURATION` — `0.3` (seconds for each half)

**`switch(scene)` behaviour:**
- If there is no current scene (first load), switch immediately with no fade.
- Otherwise start a fade-out: set `_fade_state = "out"`, `_pending = scene`. Do **not** call `on_exit`/`on_enter` yet.

**`update(dt)` additions:**
- `"out"`: increase `_fade_alpha` by `dt / FADE_DURATION`. When `>= 1.0`: clamp to 1, call `current:on_exit()`, set `current = _pending`, call `current:on_enter()`, set `_fade_state = "in"`.
- `"in"`: decrease `_fade_alpha` by `dt / FADE_DURATION`. When `<= 0.0`: clamp to 0, set `_fade_state = "idle"`, clear `_pending`.
- During both states, still call `self.current:update(dt)` so the new scene animates during fade-in.

**`draw()` additions:**
After `self.current:draw()`, if `_fade_alpha > 0` draw a black rectangle over the full logical canvas:

```lua
love.graphics.setColor(0, 0, 0, self._fade_alpha)
love.graphics.rectangle("fill", 0, 0, config.LOGICAL_W, config.LOGICAL_H)
love.graphics.setColor(1, 1, 1, 1)
```

This works because scenes always pair `camera:attach()` / `camera:detach()`, so after `draw()` returns the transform is back to canvas-space identity.

## What stays the same

- All individual scenes (`StartScene`, `StoreScene`, `BuyScene`, `SettingsMenu`) are unchanged.
- `on_exit` and `on_enter` are called at exactly the same logical moment — just deferred to the midpoint of the transition.
- The `SettingsMenu` overlay is managed outside SceneManager (in `main.lua`) and does **not** get a fade.
- First scene load (no previous scene) switches instantly, no fade.

## Open questions

None — all decisions confirmed with the user.
