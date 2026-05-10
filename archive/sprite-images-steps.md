# Sprite Images Steps

Goal: replace every colored-rectangle placeholder with a real PNG. `Sprite` already supports this — if `sprite.image` is set, `draw()` calls `love.graphics.draw(image)` instead of `rectangle("fill")`.

---

## All Sprites and Their Sizes

### Player — `lua/game/player.lua`

4 variants, each **120 × 240 px**. Set as a SpriteSet; swap on walk/hold state.

| Filename | State |
|----------|-------|
| `assets/player_idle.png` | standing, empty hands |
| `assets/player_walk.png` | walking, empty hands |
| `assets/player_idle_held.png` | standing, holding item |
| `assets/player_walk_held.png` | walking, holding item |

---

### Customer — `lua/game/customer.lua`

| Filename | Size | Notes |
|----------|------|-------|
| `assets/customer.png` | **120 × 240 px** | Single body sprite; `sprite.color` still applied as a tint, so scripted customers' `body_color` will tint the image automatically |
| `assets/customer_bubble.png` | **60 × 60 px** | Plant-request speech bubble shape; `bubble.color` tints it to the plant's stage-3 color |

---

### Plants — `lua/game/items/plant.lua`

Each plant type has 3 stage sprites, all **120 × 120 px**. 18 images total.

| Filename | Plant | Stage |
|----------|-------|-------|
| `assets/plant_1_1.png` | Fern | 1 (baby) |
| `assets/plant_1_2.png` | Fern | 2 (growing) |
| `assets/plant_1_3.png` | Fern | 3 (done) |
| `assets/plant_2_1.png` | Cactus | 1 |
| `assets/plant_2_2.png` | Cactus | 2 |
| `assets/plant_2_3.png` | Cactus | 3 |
| `assets/plant_3_1.png` | Rose | 1 |
| `assets/plant_3_2.png` | Rose | 2 |
| `assets/plant_3_3.png` | Rose | 3 |
| `assets/plant_4_1.png` | Sunflower | 1 |
| `assets/plant_4_2.png` | Sunflower | 2 |
| `assets/plant_4_3.png` | Sunflower | 3 |
| `assets/plant_5_1.png` | Lavender | 1 |
| `assets/plant_5_2.png` | Lavender | 2 |
| `assets/plant_5_3.png` | Lavender | 3 |
| `assets/plant_6_1.png` | Golden Lotus | 1 |
| `assets/plant_6_2.png` | Golden Lotus | 2 |
| `assets/plant_6_3.png` | Golden Lotus | 3 |

Plant ready bubble (watering indicator): **60 × 60 px**

| Filename | Notes |
|----------|-------|
| `assets/plant_bubble.png` | Yellow exclamation / droplet; same image for all plant types |

---

### Items — `lua/game/items/`

All items are **120 × 120 px**.

| Filename | Item | Notes |
|----------|------|-------|
| `assets/watering_can.png` | Watering Can | |
| `assets/grafter_empty.png` | Grafter | used when `loaded_plant == nil`; color tint switches orange → yellow already |
| `assets/grafter_loaded.png` | Grafter | shown when a clone is stored |
| `assets/sell_bin.png` | Sell Bin | |
| `assets/pc_store.png` | PC Store | |

---

### Slot — `lua/game/slot.lua`

| Filename | Size | Notes |
|----------|------|-------|
| `assets/slot.png` | **200 × 200 px** | Replaces the border (200×200) + inset bg (198×198) rectangles; draw as one image |

---

### Cashier Wall — `lua/game/scenes/store_scene.lua`

| Filename | Size | Notes |
|----------|------|-------|
| `assets/cashier_wall.png` | **400 × 800 px** | The swap point is already marked in `_setup_store()` with a comment |

---

## Steps

### Step 1 — Create `assets/` directory and add all PNGs

- [x] Create `assets/` at the project root
- [x] Add all images listed above at the exact pixel dimensions

### Step 2 — Load images at startup

Create `lua/game/assets.lua` that loads every image once and returns a table:

```lua
local A = {}
A.player_idle      = love.graphics.newImage("assets/player_idle.png")
A.player_walk      = love.graphics.newImage("assets/player_walk.png")
-- ... etc
return A
```

Require it once in `main.lua` (or `love.load`) and pass/share as needed.

### Step 3 — Player (`player.lua`)

- [x] Require assets; set `idle.image`, `walk.image`, `idle_held.image`, `walk_held.image` in `Player.new()`

### Step 4 — Customer (`customer.lua`)

- [x] Set `self.sprite.image` to `assets/customer.png` in `Customer.new()`
- [x] Set `self.bubble.image` to `assets/customer_bubble.png` in `Customer.new()`

### Step 5 — Plants (`plant.lua`)

- [x] In the stage loop, set `s.image = A["plant_" .. plant_type .. "_" .. i]`
- [x] Set `self.bubble.image = A.plant_bubble`

### Step 6 — Items

- [x] `watering_can.lua` — set `self.sprite.image = A.watering_can`
- [x] `grafter.lua` — set `self.sprite.image = A.grafter_empty` in `new()`; swap to `A.grafter_loaded` in `interact()` and back on unload
- [x] `sell_bin.lua` — set `self.sprite.image = A.sell_bin`
- [x] `pc_store.lua` — set `self.sprite.image = A.pc_store`

### Step 7 — Slot (`slot.lua`)

- [x] Replace the two rectangle sprites (`border` + `bg`) with a single `Sprite` using `assets/slot.png`
- [x] Update `draw()` accordingly

### Step 8 — Cashier Wall (`store_scene.lua`)

- [x] Replace the canvas-generation block with `love.graphics.newImage("assets/cashier_wall.png")` (swap point already marked in the code)

---

## Notes

- `Sprite.color` still applies as a tint on top of any image, so existing color logic (customer body tint, bubble color) works without changes
- Grafter's color changes (orange ↔ yellow) can either remain as tints on a single image or use two separate images (step 6 above uses two)
- Plant stage colors in `plant_data.lua` become redundant once real images are in place, but can stay for the BuyScene preview rectangles in `buy_scene.lua`
