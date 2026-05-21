# Love2D Game Architecture

---

## Core Classes

Reusable engine-level classes with no game-specific knowledge.

---

### Sprite

A single drawable unit at a world position.

**Properties**
- `x`, `y` — world position (top-left)
- `width`, `height` — dimensions in pixels
- `scale_x`, `scale_y` — scale factors (default `1`)
- `visible` — bool, skips draw if false
- `color` — tint `{r, g, b, a}` (defaults to white `{1,1,1,1}`)
- `image` — Love2D image object; if nil, draws a filled rectangle instead
- `shader` — optional Love2D shader applied during `draw()`, reset after

**Methods**
- `new(x, y, w, h)` — constructor
- `draw()` — if `image` is set, scales it to fill `width × height` exactly; otherwise draws a filled rectangle at those dimensions; applies `color` as a tint in both cases
- `update(dt)` — no-op hook

**Notes**
- Color tinting works identically for images and rectangles; a white image tinted `{r,g,b,1}` looks the same as a rectangle drawn in that color
- Handles the Love2D transform push/pop internally; color is reset to `{1,1,1,1}` after each draw

---

### SpriteSet

A named collection of Sprites with one active at a time.

**Properties**
- `sprites` — table of `name -> Sprite`
- `current` — name of the active sprite
- `x`, `y` — world position; forwarded to the active sprite every `draw()`
- `visible` — if false, nothing draws

**Methods**
- `new()` — constructor
- `add(name, sprite)` — register a sprite under a name
- `set(name)` — switch the active sprite
- `_active()` — returns the current Sprite
- `draw()` — copies `x`/`y` to the active sprite, then calls `sprite:draw()`
- `update(dt)` — delegates to the current active sprite

**Notes**
- Implements the same `draw()` / `update(dt)` interface as Sprite, so it is a drop-in anywhere a Sprite is expected
- `color`, `scale_x`, `scale_y` are per-sprite properties, not SpriteSet-level; set them directly on each Sprite after `add()`

---

### Drawer

Manages and renders all registered drawables each frame.

**Properties**
- `layers` — ordered list of `{sprite, priority}` entries

**Methods**
- `add(sprite, priority)` — register a drawable; lower priority = drawn first (behind)
- `draw()` — called once per `love.draw()`; iterates layers in priority order, calls `sprite:draw()` on each
- `clear()` — remove all entries

**Notes**
- Sorting happens on `add()`, not every frame
- Any object with a `draw()` method can be registered, not just Sprites

---

### Camera

Controls the viewport — what portion of the world is visible.

**Properties**
- `x`, `y` — world position the camera is centered on
- `zoom` — scale factor (default: `1.0`)

**Methods**
- `new(x, y)` — constructor
- `attach()` — push camera transform onto the Love2D transform stack (call before drawing)
- `detach()` — pop camera transform (call after drawing)
- `to_world(sx, sy)` — convert screen coordinates to world coordinates
- `to_screen(wx, wy)` — convert world coordinates to screen coordinates
- `follow(target, lerp)` — smoothly track `target.x/y`; `lerp` 0 = instant, 1 = no movement

**StoreScene camera rules (applied after `follow()` each frame)**
- `camera.y` is locked to `CAMERA_Y = 440` (no vertical follow)
- `camera.x` is clamped so neither screen edge overruns the world: left bound = `-ZONE_WIDTH + 640`, right bound = `store:width() - 640`; ensures the cashier zone far-left and store far-right are never exposed

---

### Scene

A self-contained game state. Owns its Drawer and Camera.

**Properties**
- `drawer` — Drawer instance for this scene
- `camera` — Camera instance for this scene

**Methods**
- `new()` — constructor
- `update(dt)` — per-frame logic (override in subclasses)
- `draw()` — wraps `drawer:draw()` inside `camera:attach()`/`camera:detach()`
- `on_enter()` — called when this scene becomes active
- `on_exit()` — calls `drawer:clear()` by default

---

### SceneManager

Holds the active scene and delegates the game loop to it.

**Properties**
- `current` — the active Scene

**Methods**
- `switch(scene)` — calls `current:on_exit()`, swaps, calls `scene:on_enter()`
- `update(dt)` — delegates to `current:update(dt)`
- `draw()` — delegates to `current:draw()`

---

## Frame Loop

```
love.update(dt)
  scene_manager:update(dt)

love.draw()
  scene_manager:draw()
    -- internally: camera:attach() → drawer:draw() → camera:detach()
```

---

## Game Classes

Game-specific classes that implement the plant store logic.

---

### Assets

Loads every PNG once at startup and returns a shared table. All other modules `require` this module directly; Love2D's module cache ensures images are only loaded once.

**Location:** `lua/game/assets.lua`

**Contents**
- `player_idle`, `player_walk`, `player_idle_held`, `player_walk_held` — player state images (120×240)
- `customer`, `customer_bubble` — customer body and plant-request bubble (120×240, 120×120)
- `plant_N[stage]` — plant images indexed as `A["plant_N"][stage]` for types 1–6, stages 1–3 (120×120 each)
- `plant_bubble` — watering-ready indicator shown above plants (60×60)
- `watering_can`, `grafter_empty`, `grafter_loaded`, `garbage_bin`, `pc_store` — item images (120×120); `grafter_loaded` is loaded but no longer referenced by grafter code
- `grafter_no_space_bubble` — optional (60×60); shown above the grafter when no empty slot is available; loaded via `try_img`
- `slot` — slot background image (120×200)
- `cashier_wall` — cashier zone wall with transparent window cutout (400×800)
- `store_wall` — repeating store wall tile (200×720); one slot wide
- `store_window` — store window frame with transparent cutout (400×720); two slots wide
- `slot_highlight` — overlay drawn on the active slot (120×200)
- `store_bg_far`, `store_bg_mid`, `store_bg_near` — parallax background layers tiled across the full world width (cashier zone + store); currently alias `shop_bg_far/mid/near`
- `speech_bubble` — 9-slice speech bubble image (96×72, margins top=12 right=12 bottom=24 left=12)
- `speech_bubble_tail` — tail graphic drawn below the speech bubble
- `sneakers`, `expand_slot` — buy-scene preview images; loaded conditionally via `try_img` (art not yet created; fall back to grey rectangle in preview)
- `wall_pattern` — optional repeating pattern texture (`assets/wall_pattern.png`); loaded with `setWrap("repeat","repeat")`; nil if the file is absent; used by the `WallPattern` shader on every wall draw
- `accessories` — table of lazily-loaded accessory images, keyed by name

**Methods**
- `load_accessory(name)` — loads `assets/accessories/<name>.png` on first call and caches the result; returns `false` (not nil) on a missing file so the cache entry is set and the disk is not re-checked

---

### Input

Maps Love2D key events to the four game actions. Game logic calls Input, never Love2D directly.

**Actions**
- `move_left`
- `move_right`
- `pick_up_down`
- `interact`

**Methods**
- `update()` — called each frame, samples key state
- `is_down(action)` — true while the key is held
- `pressed(action)` — true only on the frame the key was pressed

---

### GameState

Shared state passed between scenes. Survives scene switches.

**Properties**
- `store` — the Store instance
- `player` — the Player instance
- `currency` — player's current funds
- `speed_level` — current speed upgrade tier (0 = base)
- `growth_level` — current Heat Lamps upgrade tier (0 = base)
- `growth_mult` — float derived from `growth_level`; multiplied into `dt` passed to the store each frame (1.0 = no change)
- `unlocked_plants` — set `{ [plant_type] = true }`; Grass (`[1]`) pre-populated; updated on plant purchase
- `stage3_counts` — `{ [plant_type] = n }`; incremented each time that plant type reaches stage 3
- `seen_scripts` — set `{ ["id:chapter"] = true }`; e.g. `"old_pete:1"`; prevents a scripted chapter from firing twice

---

### Player

The player character. Moves left/right into the cashier zone, holds at most one item.

**Properties**
- `x` — world position (can go negative into cashier zone)
- `held_item` — the Item currently held, or `nil`
- `speed` — movement speed in px/s; defaults to 220, increased by speed upgrades
- `sprite` — SpriteSet with four variants: `idle`, `walk`, `idle_held`, `walk_held`; each backed by a PNG image
- `_speed_color` — `{r,g,b,a}` replacement color for the current speed tier; defaults to `{1,1,1,1}` (white) at base level

**Methods**
- `new(x)` — constructor
- `set_speed_level(level, color)` — stores `color` as `_speed_color`; called by BuyScene after a speed purchase
- `update(dt, input, store)` — handle movement and animation frame switching
- `active_slot(store)` — returns the slot the player is standing over
- `draw()` — applies `ColorReplace` with `_speed_color` as primary (no secondary); draws sprite; clears shader; then draws held item above the player

---

### Item

Base class for all carriable/interactable objects in the store.

**Properties**
- `sprite` — Sprite or SpriteSet
- `carriable` — bool
- `sellable` — bool (false for PC Store)
- `name` — display string

**Methods**
- `new()` — constructor
- `interact(player, store, scene_manager)` — called when player presses Interact
- `draw()` — delegates to sprite

**Subclasses**
- `WateringCan` — interact waters the plant in the player's active slot
- `Grafter` — clones a stage-3 plant; auto-spawns the clone into the nearest empty slot; emits a no-space bubble if no slot is available
- `PCStore` — interact switches to BuyScene; only works when placed in a slot
- `GarbageBin` — discard station; F while holding any sellable item discards it
- `Plant` — has stage and cooldown timer; not directly usable as a tool

---

### Plant

An Item subclass. Tracks growth state via a cooldown timer.

**Properties**
- `plant_type` — integer 1–6
- `stage` — integer 1–3 (baby, growing, done)
- `cooldown` — seconds remaining until ready for water
- `ready` — bool, true when `cooldown <= 0`
- `sprite` — SpriteSet keyed by stage (`"1"` / `"2"` / `"3"`); each frame backed by a PNG image, tinted by the plant's stage color from `plant_data`
- `bubble` — Sprite (60×60) shown above the plant when ready; tinted yellow

**Methods**
- `update(dt)` — count down `cooldown`; flips `ready` and `bubble.visible` when it hits zero
- `water()` — if `ready`, advance stage, reset cooldown, hide bubble; otherwise no-op
- `draw()` — renders `sprite`
- `draw_bubble()` — if `bubble.visible`, positions and draws the bubble above the plant

---

### Grafter

An Item subclass. Clones a stage-3 plant.

**Properties**
- `bubble` — Sprite (60×60) shown above the grafter when no empty slot is available; image = `A.grafter_no_space_bubble`
- `_bubble_timer` — seconds remaining before the no-space bubble hides; counts down in `update(dt)`
- `sprite` — single Sprite; always `grafter_empty` image

**Methods**
- `interact(player, store, scene_manager)` — if player is holding grafter and active slot has a stage-3 plant: finds the nearest empty slot (by index distance; ties go to lower index); if found, resets the source plant to stage 1 and places a new clone directly into that slot; if no empty slot, shows the no-space bubble for 1.5 s
- `update(dt)` — counts down `_bubble_timer`; hides bubble when it reaches zero
- `draw_bubble()` — if `bubble.visible`, positions and draws the no-space bubble above the grafter sprite
- `draw()` — draws grafter sprite

---

### Slot

One cell in the store. Holds at most one item.

**Properties**
- `index` — position in the store array
- `x`, `y` — world position
- `item` — the Item in this slot, or `nil`
- `bg` — Sprite backed by `slot.png` (120×200)

**Methods**
- `new(index, slot_width)` — constructor
- `update(dt)` — delegates to item; positions item sprite within the slot
- `draw()` — draws slot background, then item if present

---

### Store

The 1D array of slots. Handles layout and growth.

**Properties**
- `slots` — ordered array of Slot
- `slot_width` — width of each slot in pixels (120)

**Methods**
- `new(initial_count, slot_width)` — constructor
- `grow()` — append one new slot at the right end
- `slot_at(x)` — return the Slot at world x position
- `update(dt)` — delegates to all slots/items
- `draw()` — delegates to all slots; no background (background drawn by `draw_bg` before the drawer)
- `draw_bg(A)` — draws store wall tiles and window frames using a group-of-4 rule: slots 1–2 of each group get `store_wall`, slots 3–4 get `store_window` (if both exist and neither is the last slot); fallback to wall tiles otherwise; each wall image is drawn through a local `draw_wall(img, x)` helper that applies `WallPattern` if `A.wall_pattern` is set; called manually in `StoreScene:draw()` before `drawer:draw()`
- `draw_bubbles()` — draws only plant ready bubbles; called at a higher drawer priority so bubbles appear above the player

---

### Customer

NPC that appears in the cashier zone and requests a specific plant.

**Properties**
- `state` — `"idle"` | `"walking_in"` | `"waiting"` | `"walking_out"`
- `plant_type` — integer type of requested plant
- `name` — display name shown in dialog (default `"Customer"`)
- `messages` — ordered array of dialog strings; empty = skip straight to plant bubble
- `msg_index` — index of the current message
- `done_talking` — bool; true once all messages have been advanced through
- `_full_text` — `"Name: message"` string for the current line; rebuilt on each `show()` / `advance()`
- `reveal_index` — number of characters currently visible (typewriter progress)
- `reveal_t` — accumulated time driving the reveal; reset with each new line
- `x`, `y` — world position
- `speed` — 80 px/s
- `sprite` — Sprite (120×240) backed by `customer.png` (white); `color` set per customer as a tint — default orange, scripted customers get a unique body color
- `bubble` — Sprite used as a visibility gate and position reference; `bubble.visible` controls whether the dialog/plant-request UI is shown; not drawn directly
- `accessory_sprite` — Sprite (120×120) drawn over the top half of the body; nil for anonymous customers or when the accessory file is missing

**Methods**
- `new(target_x, exit_x, y)` — constructor; `state = "idle"`
- `show(cfg)` — accepts `{ plant_type, messages, name, body_color, accessory }`; places customer at `exit_x` and begins walk-in; `accessory` is a string key passed to `A.load_accessory()`
- `advance()` — increments `msg_index`; sets `done_talking` after the last message; resets `reveal_index`/`reveal_t`/`_full_text` for the new line
- `line_complete()` — returns true if `done_talking` or `reveal_index >= #_full_text`
- `skip_reveal()` — snaps `reveal_index` to the end of the current line instantly
- `on_last_message()` — returns `done_talking`
- `serve()` — begin walking out (called on successful sale)
- `arrived()` — returns `state == "waiting"`
- `active()` — returns `state ~= "idle"`
- `update(dt)` — advances walk-in / walk-out movement; advances typewriter reveal while `bubble.visible` and not `done_talking`; positions sprite, bubble, and accessory sprite
- `draw()` — applies `ColorReplace` with `_primary` and `_secondary`; draws body sprite and accessory sprite; clears shader
- `draw_bubble()` — during dialog: draws 9-slice `speech_bubble` sized to the full line width with `speech_bubble_tail`, then prints the revealed substring on top; once `done_talking`: draws a 9-slice speech bubble containing the stage-3 plant image (80×80 inside 12px padding)

---

## Shaders

### ColorReplace

Replaces pure-red or pure-blue pixels in a sprite with runtime colors. Used by Player and Customer.

**Files**
- `assets/shaders/color_replace.glsl` — GLSL source loaded from disk
- `lua/game/shaders/color_replace.lua` — wrapper; `require`-cached so the shader is compiled once

**GLSL logic**
- Pure red pixel (`r > 0.9, g < 0.1, b < 0.1`) → replaced with `replace_color_a`
- Pure blue pixel (`b > 0.9, r < 0.1, g < 0.1`) → replaced with `replace_color_b`
- All other pixels → pass through unchanged

**API**
- `apply(primary, secondary)` — sends both colors and activates the shader; `secondary` is optional, defaults to `{0,0,0,0}`
- `clear()` — resets to the default Love2D shader

**Usage**
- Player: `apply(speed_tier_color)` — red mask pixels show the current speed tier color
- Customer: `apply(primary, secondary)` — red pixels = body color, blue pixels = secondary (shadow/detail) color

---

### WallPattern

Tiles a repeating pattern texture over wall and window images. Applied to every wall draw call in both `Store:draw_bg` and the cashier wall in `StoreScene`. Gracefully no-ops if `A.wall_pattern` is nil (art missing).

**Files**
- `assets/shaders/wall_pattern.glsl` — GLSL source
- `lua/game/shaders/wall_pattern.lua` — wrapper; `require`-cached

**GLSL logic**
- Pure-red pixels (`r > 0.9, g < 0.1, b < 0.1`) in the wall image are replaced by a sample from `pattern_tex`, tiled via `fract(world_pos / pattern_size)`
- All other pixels pass through unchanged
- `world_origin` + `uv * tile_size` reconstructs the world position of each pixel so the pattern is continuous across tiles regardless of where in the world each wall image is drawn

**API**
- `apply(pattern_img, world_x, world_y, tile_img)` — sends `pattern_tex`, `pattern_size`, `world_origin`, `tile_size` and activates the shader
- `clear()` — resets to the default Love2D shader

**Assets**
- `assets/wall_pattern.png` — loaded with `setWrap("repeat", "repeat")`; optional (`try_img`); `A.wall_pattern` is nil if the file is absent

---

### CRT

Full-screen post-processing effect applied over the entire BuyScene. Renders the scene to an off-screen canvas, then draws it through this shader.

**Files**
- `assets/shaders/crt.glsl` — GLSL source
- `lua/game/shaders/crt.lua` — wrapper; `require`-cached so the shader is compiled once

**GLSL effects (applied in order)**
1. **Barrel distortion** — mild outward warp; pixels outside [0,1] after distortion are output as black, giving a rounded-screen border
2. **Chromatic aberration** — red channel sampled slightly right, blue slightly left
3. **Scanlines** — `sin`-based horizontal banding that dims every other row by ~7%
4. **Vignette** — soft edge darkening derived from `uv * (1 - uv)`

**API**
- `apply()` — activates the shader
- `clear()` — resets to the default Love2D shader

**Canvas pattern (BuyScene)**
```
prev_canvas = love.graphics.getCanvas()   -- save main.lua's canvas
setCanvas(self.canvas)                    -- render scene here
  ... all draw calls ...
setCanvas(prev_canvas)                    -- restore; draw result onto main canvas
CRT.apply()
draw(self.canvas, 0, 0)
CRT.clear()
```
`prev_canvas` must be saved and restored (not reset to nil) because `main.lua` already renders inside its own `setCanvas(canvas)` call.

---

### Sway

Per-sprite horizontal wave distortion applied to the mid and near parallax background layers in StoreScene each frame.

**Files**
- `assets/shaders/sway.glsl` — GLSL source
- `lua/game/shaders/sway.lua` — wrapper; `require`-cached

**GLSL logic**
- Extern `float time` drives animation; extern `float amplitude` controls displacement intensity
- `uv.x` is shifted by `sin(time * 0.6) * amplitude * (1.0 - uv.y)` — `(1.0 - uv.y)` anchors the bottom (`uv.y = 1`) and scales displacement up to full at the top (`uv.y = 0`), producing a pendulum sway
- The shifted UV is passed to `Texel(MainTex, shifted_uv)` and the result is multiplied by the vertex `color`

**API**
- `apply(time, amplitude)` — sends both externs and activates the shader
- `clear()` — resets to the default Love2D shader

**Usage (StoreScene)**
- `self._sway_time` is initialised to `0` in `_setup_store()` and accumulated each frame via `self._sway_time = self._sway_time + dt`
- In `draw()`, the mid layer (`p=0.20`) is wrapped with `Sway.apply(self._sway_time, 0.004)` / `Sway.clear()`
- The near layer (`p=0.45`) is wrapped with `Sway.apply(self._sway_time, 0.007)` / `Sway.clear()`
- The far layer (`p=0.05`) is drawn without any shader
- `StoreScene:draw()` also writes `gs.store.sway_time = self._sway_time` immediately before `self.drawer:draw()`; `Store:draw()` forwards this to `Slot:draw(sway_time)`, which wraps `item:draw()` with `Sway.apply` / `Sway.clear` when `sway_time` is non-nil and `item.ready ~= true` — thirsty plants (`ready == true`) are skipped and stay still

---

## Scenes

### StartScene

The first scene shown on launch. Pure screen-space UI — overrides `draw()` entirely, no camera transform.

**Location:** `lua/game/scenes/start_scene.lua`

**Properties**
- `selected` — index of the highlighted menu item (1 = New Game, 2 = Continue, 3 = Exit)
- `_font_title`, `_font_btn` — Love2D fonts created in `on_enter()`; stored on the scene so they are not recreated every frame
- `_prev_up`, `_prev_down`, `_prev_confirm` — previous-frame key states for edge detection

**Menu items**
- **New Game** — constructs and switches to `StoreScene` (same as Continue for now)
- **Continue** — constructs and switches to `StoreScene`
- **Exit** — calls `love.event.quit()`

**Navigation keys** (handled with raw `love.keyboard.isDown` + edge detection, not via the `Input` module)
- Up / W — move selection up
- Down / S — move selection down
- Enter / Space / F — confirm

**Notes**
- Fonts are saved and restored around `draw()` so the global Love2D font state is unchanged when `StoreScene` draws next frame
- `StoreScene` is `require`d lazily inside `_confirm()`, not at module load time, to avoid a circular load order

---

### BuyScene

The PC store carousel. Pure screen-space UI — overrides `draw()` entirely, no camera transform. Entire output is post-processed through the CRT shader.

**Location:** `lua/game/scenes/buy_scene.lua`

**Properties**
- `selected` — index of the currently highlighted catalogue entry
- `canvas` — 1280×720 Love2D canvas; scene draws into this each frame, then it is composited to the main canvas via the CRT shader

**Rendering**
1. Save `prev_canvas = love.graphics.getCanvas()` (main.lua's game canvas)
2. `setCanvas(self.canvas)` → clear → draw all UI
3. `setCanvas(prev_canvas)` → draw canvas with `CRT.apply()` → `CRT.clear()`

Saving and restoring `prev_canvas` is required because `main.lua` already renders all scenes inside its own `setCanvas(main_canvas)` block; resetting to `nil` would bypass that and produce a black frame.

---

## Testing

Three ways to run the game:

| Command | Window | Graphics | Input driven by |
|---------|--------|----------|-----------------|
| `love .` | real | real | keyboard |
| `love . --headless tests/foo.lua` | none | stubbed | `HeadlessInput` |
| `love . --visual tests/foo.lua` | real | real | `HeadlessInput` |

**Headless mode** (`--headless`) stubs all Love2D graphics/audio modules before any game code loads, so tests run without a window or GPU. `runner.run(test_file)` executes the test file in a `pcall` and quits with exit code 0 (pass) or 1 (fail).

**Visual mode** (`--visual`) opens a real window with full graphics but replaces the keyboard input with `HeadlessInput`. The test file runs inside a Lua coroutine; `runner.tick` yields after each frame update so `love.draw` renders between steps. Slow `walk_to` frames run at frame rate; `fast_forward_until` frames (dt = 1.0) fast-forward visually. Pass/fail prints to the terminal when the test completes.

**Test infrastructure** — `lua/headless/`

| File | Purpose |
|------|---------|
| `stubs.lua` | Installs no-op `love.graphics`, `love.keyboard`, `love.filesystem` globals before game modules load |
| `input.lua` | `HeadlessInput` — scriptable `Input` drop-in; `press()` / `hold()` / `release()` |
| `runner.lua` | `setup(factory)`, `tick(input, sm, n, dt)`, `run(test_file)`; `_visual` flag enables coroutine-yield mode |

**Test files** — `tests/`

| File | What it tests |
|------|---------------|
| `test_basics.lua` | Initial currency, player moves right when `move_right` is held |
| `test_golden_lotus.lua` | Full grow-and-sell loop for 3 grass plants then one Golden Lotus; asserts currency increases and prints elapsed simulated seconds |

---

## Layer Priorities (Drawer)

| Priority | Content |
|----------|---------|
| (pre-drawer) | Parallax background layers (`store_bg_far/mid/near`) — tiled across full world width (-ZONE_WIDTH → store:width()) with p = 0.05/0.20/0.45; drawn manually before `drawer:draw()` |
| (pre-drawer) | Store wall tiles and window frames (`Store:draw_bg`) — drawn on top of parallax, before drawer |
| 0 | Store (slots, items) |
| 1 | Customer body |
| 2 | Cashier wall (`cashier_wall.png` with transparent window cutout) |
| 2.5 | Cashier floor (tiled `slot.png` across `x = -400` to `0`) |
| 3 | Plant ready bubbles (`Store:draw_bubbles()`) |
| 4 | Player (+ held item) |
| 5 | Customer speech / plant bubble |
