## Code Review Checklist

- [x] **Bug** — `lua/game/player.lua:47` — `set_speed_level` accepts `level` but never stores it; rename to `set_speed_color` or add `self.speed_level = level`
- [x] **Bug** — `lua/game/scenes/store_scene.lua:73` — remove dead `slot` arg from `BuyScene.new(...)` call; `BuyScene.new` only takes 4 params and silently drops it
- [x] **Dead code** — `lua/game/assets.lua:33` — delete `A.grafter_loaded = img(...)` line; `grafter_loaded` is never referenced anywhere
- [x] **Code quality** — `lua/game/scenes/buy_scene.lua:294` — change `local y = 652` to `y = 652` (or rename to `hint_y`) to avoid shadowing the outer `y` declared on line 215
- [x] **Code quality** — `lua/game/scenes/settings_menu.lua:22-27` — move `is_open`, `selected`, `_prev_up`, `_prev_down`, `_prev_confirm`, `_prev_escape` out of the class table and into `new()` as per-instance fields
- [x] **Code quality** — `lua/game/scenes/store_scene.lua:402` — add `local A = require("lua/game/assets")` at the top of the file; remove the per-frame `require` inside `draw()`
- [x] **Code quality** — `main.lua:125` — cache `require("lua/headless/runner")` as a module-level local instead of calling it inside `love.draw()` every frame
- [x] **Design inconsistency** — `lua/game/scenes/start_scene.lua:38-40` — replace hardcoded `love.keyboard.isDown` calls with the passed-in `input` object so menu navigation respects remapped keybinds
- [x] **Code quality** — `lua/game/scenes/store_scene.lua:226` — replace magic number `640` with a named constant (e.g. add `LOGICAL_W = 1280` to `lua/game/config.lua` and use `LOGICAL_W / 2`)
