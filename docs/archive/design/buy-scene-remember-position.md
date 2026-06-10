## Goal

Remember the player's last carousel position in the PC Buy Scene so returning to it resumes at the previously selected item rather than always defaulting to item 1 (the first plant).

## Affected files

- `lua/game/scenes/store_scene.lua` — the two `buy_scene_factory` lambdas (`_setup_store` and `_wire_pc_store`) currently call `BuyScene.new(...)` on every invocation; change them to create the instance once and cache it

## What changes

`StoreScene._setup_store` and `StoreScene._wire_pc_store` each define a `buy_scene_factory` lambda that calls `BuyScene.new(...)` fresh on every invocation. This means `BuyScene.selected` is reset to `1` every time the player opens the PC store.

The fix: create the `BuyScene` once per `StoreScene` lifetime, cache it on `self` (e.g. `self._buy_scene`), and have the factory return that cached instance. Because `selected` is just a field on the object, it naturally persists across visits with no extra wiring.

Both factory definitions must use the same cached instance:
- `_setup_store`: create `self._buy_scene = BuyScene.new(...)` once, factory returns `self._buy_scene`
- `_wire_pc_store`: reuse `self._buy_scene` (already created by `_setup_store`) instead of constructing a new one

The canvas (`love.graphics.newCanvas`) is also only created once — a minor efficiency win.

## What stays the same

- `BuyScene` internals are unchanged
- `GameState`, `to_save`, `from_save`, and save file format are untouched
- Carousel position resets to item 1 on a fresh launch (session-only persistence)
- All other StoreScene, BuyScene, and PCStore behaviour is unchanged

## Open questions

None.
