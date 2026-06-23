## Goal

Add a Golden Idol as a purchasable item in the PC store for $4000. It is purely decorative — it can be picked up and placed in slots like any other item, but has no gameplay effect. Multiple can be purchased.

## Affected files

- `lua/game/items/golden_idol.lua` — new item class
- `lua/game/scenes/buy_scene.lua` — add catalogue entry and purchase handler
- `lua/game/assets.lua` — register placeholder sprite
- `lua/game/game_state.lua` — add serialization support
- `assets/images/golden_idol.png` — placeholder gold sprite (generated programmatically)

## What changes

- New `GoldenIdol` item class extending `Item`. No `interact` override — purely carriable and placeable. Sprite is a 6×6 unit image (same size class as other tools).
- Placeholder PNG: a solid gold (#FFD700) 32×32 square, generated via Python and saved to `assets/images/golden_idol.png`.
- `A.golden_idol` registered in `assets.lua` with `img()`.
- New CATALOGUE entry in `buy_scene.lua`:
  - label: `"Golden Idol"`
  - description: `"A shiny golden idol.\nPurely decorative."`
  - cost: `4000`
  - kind: `"golden_idol"`
  - image: `A.golden_idol`
- `_confirm()` case for `kind == "golden_idol"`: deduct cost, create `GoldenIdol.new()`, assign to `gs.player.held_item`, play `shop_buy` sound, switch back to StoreScene.
- Serialization in `game_state.lua`: type code `"golden_idol"` for save/load, same pattern as `"watering_can"` etc.

## What stays the same

- No new gameplay mechanics or effects.
- Pickup/putdown uses the existing player slot interaction — no changes to `player.lua` or `store.lua`.
- All other catalogue items unchanged.
- No tier or upgrade system needed.

## Open questions

None — all answered before design:
- Purely decorative (no effect)
- Multiple purchases allowed (no one-time guard)
- Placeholder sprite (gold rectangle PNG)
