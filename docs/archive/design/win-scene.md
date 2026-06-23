# Win Scene Design

## Goal

Make the Golden Idol interactable in the store. Interacting with it opens a new `WinScene` — a full-screen image. Pressing cancel returns to the store. Music does not change.

## Affected files

- `lua/game/items/golden_idol.lua` — add `interact()` method
- `lua/game/scenes/win_scene.lua` — new scene file
- `lua/game/scenes/store_scene.lua` — create `_win_scene` and wire factory into GoldenIdol
- `lua/game/assets.lua` — register win scene image

## What changes

### GoldenIdol

Add an `interact(player, store, scene_manager)` method. Like `PCStore`, the idol stores a `win_scene_factory` closure set by StoreScene after construction. When interact is called, it calls `scene_manager:switch(self.win_scene_factory())`.

### WinScene

New scene at `lua/game/scenes/win_scene.lua`. Constructor signature matches BuyScene:

```lua
WinScene.new(game_state, input, scene_manager, store_scene)
```

- `draw()`: draws `A.win_scene` stretched to fill the logical resolution (1280×720), no camera transform needed — draw directly in screen space
- `update(dt)`: if `input:pressed("cancel")`, switch back to `store_scene`
- `on_enter()` / `on_exit()`: no special logic needed beyond base class
- Does **not** touch music

Fade in/out is free — SceneManager handles it automatically via `switch()`.

### StoreScene

In `_setup_store()` (alongside where `_buy_scene` is created), add:

```lua
self._win_scene = WinScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref)
local win_scene_factory = function() return self_ref._win_scene end
```

After creating each `GoldenIdol` (at purchase in BuyScene) the factory must be wired in. Mirror the pattern used for Laptop/buy_scene_factory:
- In `StoreScene:on_enter()`, walk held item and all store slots; if any is a GoldenIdol, set its `win_scene_factory`.
- BuyScene already sets `gs.player.held_item = GoldenIdol.new()` on purchase — on_enter() runs right after the switch back to StoreScene, so that covers the newly purchased idol too.

### Assets

Register in `lua/game/assets.lua`:

```lua
A.win_scene = img("assets/images/win_scene.png")
```

Image must exist at `assets/images/win_scene.png` before the game can run.

## What stays the same

- Scene fade timing (0.3 s, handled by SceneManager)
- Music — no calls to Sound.play_music / Sound.fade_music / Sound.stop_music
- BuyScene purchase flow — idol is still purchased and held exactly as before
- Save/load — no new state to persist

## Open questions

1. **Win scene image filename** — assumed `assets/images/win_scene.png`. Confirm or supply the actual filename before Phase 3.
