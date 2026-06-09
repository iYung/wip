# Checklist: Coin Icon for Price Display

- [x] `lua/game/assets.lua` — add `A.coin = img("assets/images/coin.png")`
- [x] `lua/game/scenes/buy_scene.lua` — strip `$` from all 5 `display_cost` assignments (lines 225, 236, 247, 257, 262)
- [x] `lua/game/scenes/buy_scene.lua` — replace price draw block with coin icon + number side-by-side, centered; "---" stays as plain text
- [x] `lua/game/scenes/buy_scene.lua` — replace top-left HUD `"Currency: " .. currency` with coin icon + number
- [x] `lua/game/scenes/store_scene.lua` — replace top-left HUD `"Currency: " .. gs.currency` with coin icon + number
