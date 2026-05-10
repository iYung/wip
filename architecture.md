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
- `watering_can`, `grafter_empty`, `grafter_loaded`, `sell_bin`, `pc_store` — item images (120×120)
- `slot` — slot background image (120×200)
- `cashier_wall` — cashier zone wall with transparent window cutout (400×800)
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
- `unlocked_plants` — set `{ [plant_type] = true }`; Fern (`[1]`) pre-populated; updated on plant purchase
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

**Methods**
- `new(x)` — constructor
- `update(dt, input, store)` — handle movement and animation frame switching
- `active_slot(store)` — returns the slot the player is standing over
- `draw()` — delegates to sprite, then draws held item above the player

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
- `Grafter` — clones a stage-3 plant; has `unload()` to reset to empty state
- `PCStore` — interact switches to BuyScene; only works when placed in a slot
- `SellBin` — sell station; acts as a target for F-interact while holding another item
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
- `loaded_plant` — a Plant instance stored inside, or `nil`
- `sprite` — single Sprite; image swaps between `grafter_empty` (orange) and `grafter_loaded` (yellow) PNGs

**Methods**
- `interact(player, store, scene_manager)` — if player is holding grafter and active slot has a stage-3 plant: resets the plant to stage 1, stores a clone; swaps to `grafter_loaded` image
- `unload()` — sets `loaded_plant = nil`, swaps back to `grafter_empty` image; called by StoreScene when the clone is placed or sold
- `draw()` — draws grafter sprite; if loaded, also draws the stored plant sprite above it

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
- `draw()` — draws store floor background, then delegates to all slots
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
- `x`, `y` — world position
- `speed` — 80 px/s
- `sprite` — Sprite (120×240) backed by `customer.png` (white); `color` set per customer as a tint — default orange, scripted customers get a unique body color
- `bubble` — Sprite (120×120) backed by `customer_bubble.png` (white); tinted to `colors[3]` of the requested plant; same dimensions as a plant sprite so it looks like the stage-3 plant
- `accessory_sprite` — Sprite (120×120) drawn over the top half of the body; nil for anonymous customers or when the accessory file is missing

**Methods**
- `new(target_x, exit_x, y)` — constructor; `state = "idle"`
- `show(cfg)` — accepts `{ plant_type, messages, name, body_color, accessory }`; places customer at `exit_x` and begins walk-in; `accessory` is a string key passed to `A.load_accessory()`
- `advance()` — increments `msg_index`; sets `done_talking` after the last message
- `on_last_message()` — returns `done_talking`
- `serve()` — begin walking out (called on successful sale)
- `arrived()` — returns `state == "waiting"`
- `active()` — returns `state ~= "idle"`
- `update(dt)` — advances walk-in / walk-out movement; positions sprite, bubble, and accessory sprite; accessory mirrors body `x`, `y`, `scale_x`, and `visible`
- `draw()` — draws body sprite, then accessory sprite if set
- `draw_bubble()` — during dialog: draws centered name + message text; once `done_talking`: draws the plant-colored bubble square

---

## Layer Priorities (Drawer)

| Priority | Content |
|----------|---------|
| 0 | Store (floor, slots, items) |
| 1 | Customer body |
| 2 | Cashier wall (`cashier_wall.png` with transparent window cutout) |
| 3 | Plant ready bubbles (`Store:draw_bubbles()`) |
| 4 | Player (+ held item) |
| 5 | Customer speech / plant bubble |
