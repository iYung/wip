## Buy Scene Remember Position Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_setup_store`, replace the `buy_scene_factory` lambda with one that creates the `BuyScene` once (`self_ref._buy_scene = BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref)`) and returns `self_ref._buy_scene` on every call. Remove the unused `local slot = gs.player:active_slot(store)` line inside the factory.

- [x] Task B — `lua/game/scenes/store_scene.lua` — In `_wire_pc_store`, replace the `factory` lambda with one that reuses the already-cached `self_ref._buy_scene` (created by `_setup_store`) rather than constructing a new `BuyScene`. Remove the unused `local slot` line. `_wire_pc_store` is only called when loading from save, so `self._buy_scene` is guaranteed to exist by the time it runs — `_setup_store` runs first in `on_enter`.
