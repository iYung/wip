## Goal

Add a headless mode to the Love2D game so that game logic (player movement, slot interaction, currency changes) can be exercised by automated tests without opening a window or requiring a GPU. Tests run via `love . -- --headless tests/test_basics.lua`. Normal gameplay is completely unaffected.

---

## Affected files

| File | Role |
|---|---|
| `conf.lua` | Disable window when headless flag is present |
| `main.lua` | Detect headless flag; branch into test runner instead of normal load/update/draw |
| `lua/headless/stubs.lua` | Inject no-op stubs into the `love` global before any game module is required |
| `lua/headless/assets.lua` | Replacement for `lua/game/assets.lua`; returns stub image objects |
| `lua/headless/input.lua` | `HeadlessInput` — scriptable action injector that satisfies the `Input` interface |
| `lua/headless/runner.lua` | Test runner helpers: `setup()`, `tick(n, dt)` |
| `tests/test_basics.lua` | First test file (asserts on currency, player position, slot contents) |

---

## What changes

### Detection — `conf.lua` and `main.lua`

Love2D passes everything after the `--` separator in the command line into the global `arg` table as `arg[1]`, `arg[2]`, etc. (indices 1-based; `arg[0]` is the game directory).

`conf.lua` checks `arg` at config time:

```lua
-- conf.lua
local headless = false
for _, v in ipairs(arg or {}) do
    if v == "--headless" then headless = true end
end

function love.conf(t)
    t.window.width    = 1280
    t.window.height   = 720
    t.window.title    = "plant game"
    t.window.resizable = true
    if headless then
        t.window.width   = 1
        t.window.height  = 1
        t.modules.window  = false
        t.modules.graphics = false
        t.modules.audio    = false
        t.modules.sound    = false
        t.modules.joystick = false
        t.modules.touch    = false
        t.modules.video    = false
    end
end
```

`main.lua` checks the same flag at load time and either runs the test path or the normal path. Because `conf.lua` already disabled the graphics module, `love.graphics` is nil at this point, so the stubs must be installed before any `require` of game modules.

```lua
-- main.lua (headless branch sketch)
local headless, test_file
for i, v in ipairs(arg or {}) do
    if v == "--headless" then headless = true end
    if headless and v:sub(1,1) ~= "-" and test_file == nil then
        test_file = v
    end
end

if headless then
    require("lua/headless/stubs")   -- installs love.graphics / love.keyboard stubs
    local runner = require("lua/headless/runner")
    runner.run(test_file)
    love.event.quit(0)
    return
end

-- normal path continues unchanged below
love.graphics.setDefaultFilter("nearest", "nearest")
...
```

### Stubs — `lua/headless/stubs.lua`

Installed into the `love` global immediately, before any game module is required. Two targets:

**`love.graphics`** — every method used at module-load time or in draw paths must exist and return safe values. Methods that return objects (e.g. `newImage`, `newCanvas`, `newShader`, `newQuad`) return lightweight stub tables with realistic sizes so layout-affecting logic (e.g. slot positioning, player bounds) behaves as in production.

Realistic stub image dimensions used:
- Default (most assets): 120×120
- Player sprites: 120×240
- Customer sprites: 120×240
- `cashier_wall`: 400×800
- `store_wall`: 200×720
- `store_window`: 400×720
- `slot`: 120×200

In practice, since `newImage` is called with the asset path, the stub can decode size from the filename pattern, or simply return 120×120 as the default (the player/customer sizes are only used in draw code, not logic). The sizes that matter for logic are `slot` (120×200 affects cashier floor tiling) and `store_wall`/`store_window` (affect draw_bg, which is draw-only). The default of 120×120 is safe for all logic paths; realistic sizes are a nice-to-have for completeness.

```lua
love.graphics = love.graphics or {}
local gfx = love.graphics
local function noop() end
local function stub_image(w, h)
    w, h = w or 120, h or 120
    return { getWidth=function() return w end,
             getHeight=function() return h end,
             getDimensions=function() return w, h end,
             setFilter=function() end }
end
setmetatable(gfx, { __index = function(_, k)
    -- default: return a no-op that returns a stub_image for "new*" names
    return function(...)
        if type(k) == "string" and k:sub(1,3) == "new" then
            return stub_image()
        end
        return noop()
    end
end })
```

Key methods to stub explicitly: `newImage`, `newCanvas`, `newShader`, `newQuad`, `newFont`, `getDimensions`, `setCanvas`, `setColor`, `setShader`, `draw`, `rectangle`, `print`, `push`, `pop`, `translate`, `scale`, `clear`, `setDefaultFilter`, `setFilter` (on canvas), `setBlendMode`.

**`love.keyboard`** — `isDown(key)` is called each frame by `lua/core/input.lua`'s `update()`. The stub returns `false` by default; `HeadlessInput` overrides actual key state instead (see below).

```lua
love.keyboard = love.keyboard or {}
love.keyboard.isDown = function(_key) return false end
```

**`love.filesystem`** — `getInfo(path)` is called by `try_img` in `assets.lua`. Stub returns `nil` so all optional assets silently become `nil`.

```lua
love.filesystem = love.filesystem or {}
love.filesystem.getInfo = function(_path) return nil end
```

### Assets stub — `lua/headless/assets.lua`

`lua/game/assets.lua` calls `love.graphics.newImage` at module load time (top-level, before any function). Rather than patching the module loader, this is handled by the `love.graphics` stub above: `newImage` returns a stub image object with `getWidth()` / `getHeight()` returning `1`.

Because `lua/game/assets.lua` uses `require("lua/game/assets")` (not a configurable path), and Lua's module cache (`package.loaded`) can be pre-populated before game modules load, the stubs file pre-registers a fake assets module:

```lua
-- inside lua/headless/stubs.lua, after love.graphics is stubbed:
package.loaded["lua/game/assets"] = nil  -- ensure fresh load through stubbed graphics
```

No separate `lua/headless/assets.lua` file is needed; the `love.graphics` stub absorbs all `newImage` calls transparently. A dedicated file remains an option if finer control is needed.

### HeadlessInput — `lua/headless/input.lua`

Satisfies the same interface as `lua/core/input.lua` (`is_down(action)`, `pressed(action)`, `update()`), but is driven by a queue of per-frame action tables rather than `love.keyboard.isDown`.

```lua
-- API
local HeadlessInput = {}
HeadlessInput.__index = HeadlessInput

function HeadlessInput.new() -> HeadlessInput

-- Queue actions to be active on the next tick only (simulates a key held for one frame)
function HeadlessInput:press(action)   -- sets down + pressed for next update
function HeadlessInput:hold(action)    -- sets down but not pressed (already-held state)
function HeadlessInput:release(action) -- clears down

-- Called once per tick by runner.tick(); drains one frame of queued state
function HeadlessInput:update()
```

`HeadlessInput` does not call `love.keyboard.isDown`; it maintains its own `_down` and `_pressed` tables, driven entirely by test calls.

### Test runner — `lua/headless/runner.lua`

```lua
-- runner.run(test_file) — loads and executes the test file, reports pass/fail, exits
-- runner.setup(scene_factory)
--                       — returns { gs, input, scene_manager } wired together
--                         scene_factory is optional; defaults to StartScene
--                         pass e.g. function(gs, input, sm) return StoreScene.new(gs, input, sm) end
--                         to start in a specific scene
-- runner.tick(input, scene_manager, n, dt)
--                       — calls input:update() then scene_manager:update(dt), n times
--                         dt defaults to 1/60
```

The test file receives `runner` as a global (or via `require`) and uses plain Lua `assert` for assertions. `runner.run` wraps execution in `pcall`, prints each test result, and sets a failure flag for the exit code.

Example test structure:

```lua
-- tests/test_basics.lua
local runner    = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

-- Default: starts at StartScene
local ctx = runner.setup()
local gs, input, sm = ctx.gs, ctx.input, ctx.sm
assert(gs.currency == 1000, "currency should start at 1000")

-- Override: start directly in StoreScene for gameplay tests
local ctx2 = runner.setup(function(gs2, inp2, sm2)
    return StoreScene.new(gs2, inp2, sm2)
end)
local gs2, input2, sm2 = ctx2.gs, ctx2.input, ctx2.sm

-- Walk right for 30 frames
input2:hold("move_right")
runner.tick(input2, sm2, 30)
assert(ctx2.gs.player.x > 100, "player should have moved right")
```

### `conf.lua` — window disable

As shown in the Detection section above, when `--headless` is found in `arg`, the window and graphics/audio/video modules are disabled. This prevents Love2D from creating a display or audio context entirely.

---

## What stays the same

- All `lua/game/` and `lua/core/` modules are unchanged. No game logic is modified.
- `love.update`, `love.draw`, `love.keypressed` in `main.lua` are unchanged for the non-headless path.
- The `Input` interface (`lua/core/input.lua`) is unchanged; `HeadlessInput` is a parallel implementation.
- Asset file paths and the `A.*` table shape are unchanged; stub images satisfy the same interface.
- Scene transitions (`SceneManager:switch`) work identically; tests can drive the game into any scene.

---

## Open questions

1. **`love.graphics.setFilter` on canvas objects** — Resolved: stub image/canvas objects include `setFilter` as a no-op method.

2. **Shader modules** — `lua/game/shaders/color_replace.lua` calls `love.graphics.newShader`. The catch-all stub covers this; explicit stub entry may be needed if shader caches state at load time.

3. **`try_img` optional assets** — Resolved: `love.filesystem.getInfo` returns `nil`; optional assets become `nil`. All call sites already guard against `nil` (the `if lvl < 1 then return end` and `if not lamp then return end` pattern in store_scene confirms this).

4. **Test exit code** — `love.event.quit(0)` used; desktop CI confirmed sufficient.

5. **`arg` in `conf.lua`** — Resolved: `arg` is available before `conf.lua` on LÖVE 11.x desktop. Guard with `arg or {}` to be safe.

6. **Scene argument for `setup()`** — Resolved: `setup(scene_factory)` accepts an optional factory function; defaults to `StartScene`.
