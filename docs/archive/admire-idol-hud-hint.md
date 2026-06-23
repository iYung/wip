## Admire Idol HUD Hint Checklist

- [x] Add "ADMIRE" hint to `_hud_labels()` — `lua/game/scenes/store_scene.lua` — add `elseif not held and slot_item and slot_item.win_scene_factory then f_label = make_label(f_icon, f_key, "ADMIRE")` inside the `player.x >= 0` block, after the "OPEN SHOP" branch
- [x] Add test coverage — `tests/test_hud_labels.lua` — add a test that verifies the "ADMIRE" label appears when hovering the Golden Idol without holding anything, and does not appear when holding it
