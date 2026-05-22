# Coding Notes

## Folder Structure

```
luagame/
├── main.lua
├── conf.lua
├── generate_assets.py   ← regenerates assets/ as solid-color PNGs
├── assets/              ← PNG images (player, customer, plants, items, slot, wall)
│   └── shaders/         ← GLSL shader source files
├── tests/               ← test files run via --headless or --visual
│   ├── test_basics.lua
│   └── test_golden_lotus.lua
└── lua/
    ├── core/
    │   ├── sprite.lua
    │   ├── spriteset.lua
    │   ├── drawer.lua
    │   ├── camera.lua
    │   ├── scene.lua
    │   └── scene_manager.lua
    ├── headless/        ← test infrastructure; not loaded in normal play
    │   ├── stubs.lua    ← no-op love.graphics/keyboard/filesystem globals
    │   ├── input.lua    ← HeadlessInput; scriptable drop-in for lua/game/input.lua
    │   └── runner.lua   ← setup / tick / run helpers
    └── game/
        ├── assets.lua       ← loads all PNGs once; require-cached
        ├── config.lua
        ├── input.lua
        ├── game_state.lua
        ├── player.lua
        ├── store.lua
        ├── slot.lua
        ├── customer.lua
        ├── items/
        │   ├── item.lua
        │   ├── watering_can.lua
        │   ├── grafter.lua
        │   ├── garbage_bin.lua
        │   ├── pc_store.lua
        │   └── plant.lua
        ├── scenes/
        │   ├── start_scene.lua
        │   ├── store_scene.lua
        │   └── buy_scene.lua
        ├── shaders/
        │   └── color_replace.lua    ← wraps color_replace.glsl; apply(primary, secondary) / clear()
        └── data/
            ├── plant_data.lua
            ├── customer_scripts.lua
            ├── speed_tiers.lua
            └── growth_tiers.lua
```

---

## Running Tests

```bash
# headless — no window, exits with code 0/1
love . --headless tests/test_golden_lotus.lua

# visual — real window, watch the test play out
love . --visual tests/test_golden_lotus.lua

# run all tests
love . --headless
```

`--headless` stubs all Love2D graphics/audio before any game code loads. `--visual` runs with a real window; `runner.tick` yields after each frame so `love.draw` fires between updates.

CI runs `love . --headless` automatically on every push to `main` and every PR — see `.github/workflows/ci.yml`.

---

## Lua Class Pattern

All classes follow the same pattern:

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new(...)
    local self = setmetatable({}, MyClass)
    -- init
    return self
end

return MyClass
```

Inheritance:

```lua
local Base = require("lua/core/sprite")
local Child = setmetatable({}, { __index = Base })
Child.__index = Child

function Child.new(...)
    local self = Base.new(...)
    return setmetatable(self, Child)
end

return Child
```

---

## Conventions

- File and variable names: `snake_case`
- Class names: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- One class per file, filename matches class name in snake_case
- Require paths are relative to project root, no leading `./`

---

## Requiring Files

```lua
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
```

---

## Images

All sprites use PNG images loaded via `lua/game/assets.lua`. Every file that needs images does:

```lua
local A = require("lua/game/assets")
self.sprite.image = A.watering_can
```

`require` caches the module, so images are only loaded once regardless of how many files require it.

`Sprite:draw()` scales the image to fill `self.width × self.height` exactly, so image pixel dimensions don't need to match the sprite's declared size:

```lua
local sx = self.width  / self.image:getWidth()
local sy = self.height / self.image:getHeight()
love.graphics.draw(self.image, 0, 0, 0, sx, sy)
```

To regenerate all PNGs (e.g. to change colors or sizes):

```
python3 generate_assets.py
```

---

## Resolution

Logical resolution: **1280×720**. Everything renders to a canvas at that size. The canvas is then scaled to fit the window while maintaining aspect ratio — letterboxed if the window is larger or a different ratio.

```lua
-- conf.lua
function love.conf(t)
    t.window.width  = 1280
    t.window.height = 720
    t.window.title  = "plant game"
    t.window.resizable = true
end
```

Scaling logic in `main.lua`:

```lua
local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
        scene_manager:draw()
    love.graphics.setCanvas()

    local sw, sh = love.graphics.getDimensions()
    local scale  = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox     = (sw - LOGICAL_W * scale) / 2
    local oy     = (sh - LOGICAL_H * scale) / 2

    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end
```

World coordinates and slot widths should be sized to feel natural at 1280×720.

---

## PC Store Catalogue

Each `CATALOGUE` entry in `buy_scene.lua` has a `description` string displayed in the shop UI. **Max 2 lines** (one `\n` allowed). Some entries (e.g. `growth_boost`) append a dynamic line at draw time — those catalogue descriptions must be 1 line so the total stays at 2.

---

## Data Tables

Game config lives in `game/data/` as plain Lua tables returning a value:

```lua
-- game/data/plant_data.lua
return {
    [1] = {
        name        = "Grass",
        description = "...",
        cost        = 1,
        sell        = 5,
        cooldowns   = { 1, 1 },
    },
    -- ...
}
```

```lua
-- game/data/customer_scripts.lua
-- Each entry is one chapter of a named character's arc.
-- Characters with the same id are chapters of the same person.
-- chapter 2 won't fire until chapter 1 has been seen, and so on.
return {
    {
        id         = "old_pete",   -- unique character key
        chapter    = 1,            -- visit number for this character
        trigger    = { plant_type = 1, count = 1 },  -- stage3_counts threshold
        name       = "Old Pete",
        body_color = {0.25, 0.45, 0.80, 1},
        plant_type = 2,            -- plant the customer wants
        accessory  = "flat_cap",   -- optional; key into assets/
        messages   = { "...", "...", "..." },
    },
    -- ...
}
```

`seen_scripts` keys use `"id:chapter"` format (e.g. `"old_pete:1"`) so each chapter is tracked independently.
