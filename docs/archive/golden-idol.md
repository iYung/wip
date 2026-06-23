## Golden Idol Checklist

- [x] Task A — `assets/images/golden_idol.png` — generate a 120×120 gold (#FFD700) placeholder PNG using Python/PIL
- [x] Task B — `lua/game/items/golden_idol.lua` — create GoldenIdol item class extending Item, 6×6 U sprite, no interact override, name = "Golden Idol"
- [x] Task C — `lua/game/assets.lua` — register `A.golden_idol = img("assets/images/golden_idol.png")` alongside the other tool assets
- [x] Task D — `lua/game/scenes/buy_scene.lua` — add CATALOGUE entry (label="Golden Idol", cost=4000, kind="golden_idol", image=A.golden_idol, description) and require GoldenIdol; add `kind == "golden_idol"` case in `_confirm()` to create GoldenIdol.new() and assign to held_item
- [x] Task E — `lua/game/game_state.lua` — add GoldenIdol require, `"golden_idol"` branch in `_item_to_data` and `_item_from_data` for save/load
