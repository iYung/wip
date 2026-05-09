# Love2D Game Architecture

---

## Core Classes

Reusable engine-level classes with no game-specific knowledge.

---

### Sprite

A single image, the base drawable unit.

**Properties**
- `x`, `y` — world position
- `width`, `height` — dimensions
- `scale_x`, `scale_y` — scale factors
- `visible` — bool, skips draw if false
- `color` — tint `{r, g, b, a}`
- `shader` — optional Love2D shader applied during `draw()`, reset after

**Methods**
- `new(x, y)` — constructor
- `draw()` — renders the sprite; called by Drawer each frame
- `update(dt)` — optional per-frame logic hook

**Notes**
- Always renders a single image
- Handles the Love2D transform push/pop internally

---

### SpriteSet

A named collection of Sprites with one active at a time.

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

## Game Classes

Game-specific classes that implement the plant store logic.

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

---

### Player

The player character. Moves left/right, holds at most one item.

**Properties**
- `x` — world position
- `held_item` — the Item currently held, or `nil`
- `sprite` — SpriteSet (walk frames a/b)

**Methods**
- `new(x)` — constructor
- `update(dt, input, store)` — handle movement and derive active slot from x
- `active_slot(store)` — returns the slot index the player is standing over
- `draw()` — delegates to sprite

---

### Item

Base class for all carriable/interactable objects in the store.

**Properties**
- `sprite` — Sprite or SpriteSet
- `carriable` — bool

**Methods**
- `new()` — constructor
- `interact(player, store)` — called when player presses Interact on this item
- `draw()` — delegates to sprite

**Subclasses**
- `WateringCan` — interact waters the plant in the player's active slot
- `Grafter` — interact clones the plant in the active slot (mechanic TBD)
- `PCStore` — interact switches to BuyScene; only works when placed in a slot
- `Plant` — has stage and watering count; not directly usable as a tool

---

### Plant

An Item subclass. Tracks growth state via a cooldown timer.

**Properties**
- `plant_type` — integer 1–6
- `stage` — integer 1–3 (baby, growing, done)
- `cooldown` — seconds remaining until ready for water
- `ready` — bool, true when `cooldown <= 0`
- `sprite` — SpriteSet keyed by stage
- `bubble` — Sprite positioned above the plant; `visible` toggled by `ready`

**Methods**
- `update(dt)` — count down `cooldown`; flips `ready` and `bubble.visible` when it hits zero
- `water()` — if `ready`, advance stage, reset `cooldown` from `PLANT_COOLDOWNS[plant_type][stage]`, hide bubble; otherwise no-op
- `draw()` — renders `sprite`, then renders `bubble` offset above if visible

**Notes**
- Plant owns and draws both sprites — no Drawer involvement for the bubble
- Bubble position is derived each draw from the plant's own x/y plus a fixed upward offset
- `PLANT_COOLDOWNS` is a data table `[plant_type][stage] -> seconds`, defined in config

---

### Slot

One cell in the store. Holds at most one item.

**Properties**
- `index` — position in the store array
- `x` — world x position (derived from index × slot_width)
- `item` — the Item in this slot, or `nil`

**Methods**
- `new(index, slot_width)` — constructor
- `draw()` — draws the slot background and delegates to item if present

---

### Store

The 1D array of slots. Handles layout and growth.

**Properties**
- `slots` — ordered array of Slot
- `slot_width` — width of each slot in pixels

**Methods**
- `new(initial_count, slot_width)` — constructor
- `grow()` — append one new slot at the designated end
- `slot_at(x)` — return the Slot at world x position
- `update(dt)` — delegates to all slots/items
- `draw()` — delegates to all slots

---

## Layer Priorities (Drawer)

| Priority | Content        |
|----------|----------------|
| 0        | Store slots    |
| 1        | Items in slots |
| 2        | Player         |
