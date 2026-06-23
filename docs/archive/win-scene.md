## Win Scene Checklist

- [x] Task A — `lua/game/assets.lua` — register `A.win_scene = img("assets/images/win_scene.png")`
- [x] Task B — `lua/game/scenes/win_scene.lua` — create WinScene: constructor takes `(game_state, input, scene_manager, store_scene)`; `draw()` draws `A.win_scene` stretched to 1280×720 in screen space (no camera); `update(dt)` switches back to `store_scene` on cancel; no music changes
- [x] Task C — `lua/game/items/golden_idol.lua` — add `win_scene_factory` field (default nil) and `interact(player, store, scene_manager)` method that calls `scene_manager:switch(self.win_scene_factory())`
- [x] Task D — `lua/game/scenes/store_scene.lua` — in `_setup_store()` create `self._win_scene` and `win_scene_factory`; in `on_enter()` walk held item and all store slots, set `win_scene_factory` on any GoldenIdol found
