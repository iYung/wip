# Checklist: Replace Default Font with Inter Variable

- [x] Create `lua/game/fonts.lua` — `PATH = "assets/fonts/InterVariable.ttf"`, expose `Fonts.new(size)`
- [x] `main.lua` — add `love.graphics.setNewFont("assets/fonts/InterVariable.ttf", 16)` in `love.load()` after setup
- [x] `lua/game/scenes/buy_scene.lua` — require `lua/game/fonts`, replace 4 module-level `newFont` calls with `Fonts.new(size)`
- [x] `lua/game/scenes/settings_menu.lua` — require `lua/game/fonts`, replace 2 `newFont` calls in `new()` with `Fonts.new(size)`
- [x] `lua/game/scenes/start_scene.lua` — require `lua/game/fonts`, replace 2 `newFont` calls in `new()` with `Fonts.new(size)`, drop `"mono"` arg from tagline font
