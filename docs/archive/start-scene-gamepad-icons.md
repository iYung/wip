## Start Scene Gamepad Icons Checklist

- [x] Task A — `lua/game/scenes/start_scene.lua` — Replace lines 176–186 (the three individual button hint draws) with a `make_label()` helper + icon-aware render loop, matching the BuyScene/StoreScene pattern. `make_label(action, label_text)` calls `icon_key_for` and returns `{ icon, text }` in gamepad mode or a plain string in keyboard mode. Draw loop: if table, draw `A[hint.icon]` (16px) then `hint.text`; else print the string. Keep positions x=1070/1150/1230, y=630 unchanged.
