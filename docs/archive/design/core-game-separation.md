## Goal

Make `/core` a self-contained, game-agnostic engine layer that can be dropped into any new Love2D project. Four changes: remove a game-to-core dependency inversion, fix a hardcoded resolution in a core primitive, move a generic infrastructure module, and move the audio engine.

## Affected files

- `lua/core/scene_manager.lua` — remove `lua/game/config` import; accept `w, h` via constructor
- `lua/core/camera.lua` — remove hardcoded `1280, 720`; accept `w, h` via constructor
- `lua/core/scene.lua` — pass `w, h` through to `Camera.new`
- `lua/game/save.lua` → move to `lua/core/save.lua`
- `lua/game/sound.lua` → move to `lua/core/sound.lua`; `Sound.load()` accepts a manifest table
- `main.lua` — pass `config.LOGICAL_W/H` to `SceneManager.new`; pass sound manifest to `Sound.load`; update require paths
- `lua/game/game_state.lua` — update save require path
- Any other file that requires `lua/game/save` or `lua/game/sound`

## What changes

### 1. scene_manager.lua — remove game/config dependency

Replace `local config = require("lua/game/config")` with constructor arguments:

```lua
function SceneManager.new(w, h)
    local self = setmetatable({}, SceneManager)
    self._w = w
    self._h = h
    ...
end
```

The fade overlay rectangle uses `self._w / self._h` instead of `config.LOGICAL_W / LOGICAL_H`.

Call site in `main.lua`:
```lua
local scene_manager = SceneManager.new(config.LOGICAL_W, config.LOGICAL_H)
```

### 2. camera.lua — remove hardcoded resolution

Replace `local LOGICAL_W, LOGICAL_H = 1280, 720` with constructor arguments:

```lua
function Camera.new(x, y, w, h)
    local self = setmetatable({}, Camera)
    self.x  = x or 0
    self.y  = y or 0
    self._w = w or 1280
    self._h = h or 720
    ...
end
```

`Camera:attach()` uses `self._w / self._h` for the centering translate. The defaults preserve existing behavior for any call site that omits them.

`lua/core/scene.lua` passes its own `w, h` through when constructing the camera:
```lua
function Scene.new(w, h)
    local self  = setmetatable({}, Scene)
    self.drawer = Drawer.new()
    self.camera = Camera.new(0, 0, w, h)
    return self
end
```

Game scenes that call `Scene.new()` (via inheritance) pass dimensions down from `main.lua` or their constructors.

### 3. save.lua — move to lua/core/save.lua

Zero game dependencies — pure Lua serializer + `love.filesystem` read/write. Move the file and update all require paths from `lua/game/save` → `lua/core/save`.

### 4. sound.lua — move to lua/core/sound.lua with manifest-based load

The audio engine (fade, `playing_intent`, `on_focus` recovery, volume control) is fully generic. The only game-specific parts are the asset paths and track names, which move to a manifest table passed to `Sound.load()`:

```lua
-- main.lua (game-specific manifest)
Sound.load({
    sfx = {
        "pick_up", "put_down", "water_plant", "plant_ready",
        "clone_success", "shop_navigate", "shop_buy", "fail",
        "menu_navigate", "menu_confirm",
    },
    music = {
        menu = { path = "assets/music/menu.mp3",       looping = true, autoplay = true },
        bg1  = { path = "assets/music/background.mp3", looping = true },
        bg2  = { path = "assets/music/background2.mp3",looping = true },
        bg3  = { path = "assets/music/background3.mp3",looping = true },
        bg4  = { path = "assets/music/background4.mp3",looping = true },
    },
    sfx_dir   = "assets/sounds/",
    animalese = "assets/sounds/animalese.wav",
})
```

All callers of `Sound.play`, `Sound.play_music`, `Sound.fade_music`, etc. are unchanged — only `Sound.load()` changes signature.

## What stays the same

- `lua/game/config.lua` is unchanged
- `lua/game/ui.lua` stays as-is (draw9 stays in game)
- All game logic, item classes, scenes, shaders are untouched
- Public API of `Save`, `Sound`, `SceneManager`, and `Camera` are unchanged (only `new()` / `load()` signatures change)

## Open questions

None — design is approved.
