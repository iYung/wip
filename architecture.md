# Love2D Game Architecture

## Core Classes

---

### Sprite

Base class for anything visual. All drawable objects inherit from this.

**Properties**
- `x`, `y` — world position
- `width`, `height` — dimensions
- `scale_x`, `scale_y` — scale factors
- `visible` — bool, skips draw if false
- `color` — tint `{r, g, b, a}`

**Methods**
- `new(x, y)` — constructor
- `draw()` — renders the sprite; called by Drawer each frame
- `update(dt)` — optional per-frame logic hook

**Notes**
- Always renders a single image
- Handles the Love2D transform push/pop internally

---

### Drawer

Manages and renders all registered sprites each frame.

**Properties**
- `layers` — ordered list of `{sprite, priority}` entries

**Methods**
- `add(sprite, priority)` — register a sprite; higher priority = drawn on top
- `draw()` — called once per `love.draw()`; iterates layers in priority order, calls `sprite:draw()` on each visible sprite
- `clear()` — remove all sprites

**Layer ordering**
- Sprites are sorted ascending by `priority` (lower number = drawn first = behind)
- Sprites with equal priority are drawn in insertion order
- Sorting happens on `add()`, not every frame

---

### Camera

Controls the viewport — what portion of the world is visible.

**Properties**
- `x`, `y` — world position the camera is centered on
- `zoom` — scale factor (default: `1.0`)

**Methods**
- `new(x, y)` — constructor
- `attach()` — push camera transform onto the Love2D transform stack (call before Drawer:draw)
- `detach()` — pop camera transform (call after Drawer:draw)
- `to_world(sx, sy)` — convert screen coordinates to world coordinates
- `to_screen(wx, wy)` — convert world coordinates to screen coordinates
- `follow(sprite, lerp)` — smoothly track a sprite; `lerp` controls lag (0 = instant, 1 = no movement)

---

### Scene

A self-contained game state. Owns its Drawer and Camera.

**Properties**
- `drawer` — Drawer instance for this scene
- `camera` — Camera instance for this scene

**Methods**
- `new()` — constructor
- `update(dt)` — per-frame logic
- `draw()` — calls `camera:attach()`, `drawer:draw()`, `camera:detach()`
- `on_enter()` — called when this scene becomes active
- `on_exit()` — called before being replaced; good place to call `drawer:clear()`

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

---

### SpriteSet

A named collection of Sprites with one active at a time. Used for multi-frame sequences like walk cycles.

**Properties**
- `sprites` — table of `name -> Sprite`
- `current` — name of the active sprite

**Methods**
- `new()` — constructor
- `add(name, sprite)` — register a sprite under a name
- `set(name)` — switch the active sprite
- `draw()` — delegates to the current active sprite
- `update(dt)` — delegates to the current active sprite

**Notes**
- Implements the same `draw()` / `update(dt)` interface as Sprite, so it can be added to a Drawer directly
- `x`, `y`, `scale_x`, `scale_y`, `visible`, `color` are forwarded to the active sprite on `set()`
