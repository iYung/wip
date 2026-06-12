## Core/Game Separation Checklist

- [x] Task A — `lua/game/save.lua` → `lua/core/save.lua` — Move the file verbatim; update the two require paths: `main.lua:31` and `lua/game/scenes/start_scene.lua:4` from `lua/game/save` → `lua/core/save`. No logic changes.

- [x] Task B — `lua/core/camera.lua`, `lua/core/scene.lua`, game scenes — Remove `local LOGICAL_W, LOGICAL_H = 1280, 720` from `camera.lua`; change `Camera.new(x, y)` → `Camera.new(x, y, w, h)` storing `self._w = w or 1280` / `self._h = h or 720`; replace `LOGICAL_W/2, LOGICAL_H/2` in `attach()` with `self._w/2, self._h/2`. Then in `scene.lua` change `Scene.new()` → `Scene.new(w, h)` and pass `Camera.new(0, 0, w, h)`. Update the three game scene call sites that call `Scene.new()` to pass `config.LOGICAL_W, config.LOGICAL_H` — `store_scene.lua:48` and `buy_scene.lua:98` already import config; `start_scene.lua:26` needs `local config = require("lua/game/config")` added.

- [x] Task C — `lua/core/scene_manager.lua`, `main.lua` — Remove `local config = require("lua/game/config")` from `scene_manager.lua`; change `SceneManager.new()` → `SceneManager.new(w, h)` storing `self._w = w or 1280` / `self._h = h or 720`; replace `config.LOGICAL_W / config.LOGICAL_H` in `draw()` with `self._w / self._h`. In `main.lua:89` change `SceneManager.new()` → `SceneManager.new(config.LOGICAL_W, config.LOGICAL_H)`. `runner.lua` calls `SceneManager.new()` without args — leave it; the defaults cover the headless case since no rendering happens.

- [x] Task D — `lua/game/sound.lua` → `lua/core/sound.lua` — Move the file; refactor `Sound.load()` to accept a manifest table instead of hardcoding paths. Internal logic (fade, `playing_intent`, `on_focus`, volume) is unchanged. The manifest shape:
  ```lua
  Sound.load({
      sfx_dir   = "assets/sounds/",
      sfx       = { "pick_up", "put_down", "water_plant", "plant_ready",
                    "clone_success", "shop_navigate", "shop_buy", "fail",
                    "menu_navigate", "menu_confirm" },
      animalese = "assets/sounds/animalese.wav",
      music = {
          menu = { path = "assets/music/menu.mp3",        autoplay = true },
          bg1  = { path = "assets/music/background.mp3"  },
          bg2  = { path = "assets/music/background2.mp3" },
          bg3  = { path = "assets/music/background3.mp3" },
          bg4  = { path = "assets/music/background4.mp3" },
      },
  })
  ```
  Move this call (currently `Sound.load()` at `main.lua:112`) to use the manifest above. Update all 10 `require("lua/game/sound")` → `require("lua/core/sound")`: `main.lua`, `lua/game/settings_state.lua`, `lua/game/customer.lua`, `lua/game/water_drone.lua`, `lua/game/items/watering_can.lua`, `lua/game/items/plant.lua`, `lua/game/items/grafter.lua`, `lua/game/scenes/settings_menu.lua`, `lua/game/scenes/start_scene.lua`, `lua/game/scenes/buy_scene.lua`, `lua/game/scenes/store_scene.lua`. All other `Sound.*` call sites are unchanged.
