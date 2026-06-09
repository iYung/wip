# Intro Slideshow

## Goal

When the player selects "New Game" from the start menu, play a four-slide fullscreen image
slideshow before entering the store. Each slide fades in, holds, then fades out. Any action
key advances to the next slide immediately. After the fourth slide the store scene loads.

## Affected files

- **NEW** `lua/game/scenes/intro_scene.lua` — the slideshow scene
- **MODIFIED** `lua/game/scenes/start_scene.lua` — New Game handler switches to IntroScene instead of StoreScene directly
- **NEW** `assets/images/intro_1.png` … `intro_4.png` — art to be supplied by user

## What changes

### IntroScene

A new `Scene` subclass with its own internal per-slide fade state machine:

```
fade_in → hold → fade_out → (next slide or StoreScene)
```

- Black overlay alpha: 1→0 during `fade_in`, constant 0 during `hold`, 0→1 during `fade_out`.
- Durations are constants at the top of the file (e.g. `FADE_DURATION = 0.5`, `HOLD_DURATION = 2.0`).
- Any `interact` or `pick_up_down` key press:
  - During `hold` only → jumps to start of `fade_out` for current slide.
  - During `fade_in` or `fade_out` → input is ignored.
- Constructed with `(game_state, input, scene_manager)` — holds `game_state` to pass through to `StoreScene`.
- On the final slide's fade_out completion (or skip): calls `scene_manager:switch(StoreScene.new(...))`.

### StartScene

In `StartScene:_confirm()`, the New Game branch (selected == 1) switches to
`IntroScene.new(GameState.new(), self.input, self.scene_manager)` instead of StoreScene directly.
Music fade (`Sound.fade_music("menu", 0, 2)`) moves into IntroScene's `on_enter` so it aligns
with the slideshow rather than firing from StartScene.

## What stays the same

- SceneManager fade (black overlay on scene switch) still runs normally — the entry into
  IntroScene gets the standard scene-switch fade.
- StoreScene, BuyScene, Save/Load flow — untouched.
- Continue, Settings, Exit paths in StartScene — untouched.

## Open questions

None — all answered before writing this doc.
