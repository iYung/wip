# Checklist: Insufficient Funds Sound

- [ ] **sound.lua** — Add `"shop_buy_fail"` to `_EVENT_NAMES` in `lua/game/sound.lua` (between `"shop_navigate"` and `"shop_buy"` at line 17)

- [ ] **buy_scene.lua** — In `BuyScene:_confirm()`, add `Sound.play("shop_buy_fail")` before the `return` on line 138 (speed boost insufficient funds)

- [ ] **buy_scene.lua** — In `BuyScene:_confirm()`, add `Sound.play("shop_buy_fail")` before the `return` on line 150 (growth boost insufficient funds)

- [ ] **buy_scene.lua** — In `BuyScene:_confirm()`, add `Sound.play("shop_buy_fail")` before the `return` on line 161 (customer cooldown insufficient funds)

- [ ] **buy_scene.lua** — In `BuyScene:_confirm()`, add `Sound.play("shop_buy_fail")` before the `return` on line 170 (drone insufficient funds)

- [ ] **buy_scene.lua** — In `BuyScene:_confirm()`, add `Sound.play("shop_buy_fail")` before the `return` on line 178 (generic items insufficient funds)

> Prerequisite: `assets/sounds/shop_buy_fail.wav` must be present before testing. `Sound.load()` uses `love.filesystem.getInfo` to skip missing files gracefully, so the code change is safe to land before the file arrives.
