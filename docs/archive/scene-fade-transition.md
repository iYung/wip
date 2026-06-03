## Scene Fade Transition Checklist

- [x] Task A — `lua/game/config.lua` — add `LOGICAL_H = 720` to the config table alongside the existing `LOGICAL_W`
- [x] Task B — `lua/core/scene_manager.lua` — add fade state machine: new fields `_fade_state`, `_fade_alpha`, `_pending`, `FADE_DURATION = 0.3`; update `switch()` to start fade-out instead of swapping immediately (skip fade when no current scene); update `update(dt)` to advance alpha and perform the scene swap at the blackout midpoint; update `draw()` to paint a black overlay using `_fade_alpha` after the scene draws
