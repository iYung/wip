# Progress

## What's Built

All MVP steps are implemented and running. Expand Store, Shop UI, Plant Types, Context HUD, Cashier Zone, Speed Upgrade, and Player Walk features complete.

Completed step files are moved to [`archive/`](archive/) — `mvp-steps.md`, `grafter-steps.md`, `expand-store-steps.md`, `shop-ui-steps.md`, `plant-types-steps.md`, `context-hud-steps.md`, `cashier-zone-steps.md`, `speed-upgrade-steps.md`, `player-walk-steps.md`.

---

### Core (`lua/core/`)

| File | What it does |
|------|-------------|
| `sprite.lua` | Single drawable unit — colored rectangle placeholder if no image loaded |
| `spriteset.lua` | Named collection of sprites, one active at a time; forwards x/y to active sprite on draw |
| `drawer.lua` | Holds sprites sorted by priority, calls draw() each frame |
| `camera.lua` | Translates world → screen; follow(target, lerp) with 0=instant, 1=no movement |
| `scene.lua` | Base class with drawer + camera; on_enter/on_exit lifecycle |
| `scene_manager.lua` | Swaps scenes, calls on_exit/on_enter, delegates update/draw |

---

### Game (`lua/game/`)

| File | What it does |
|------|-------------|
| `config.lua` | Shared constants — `U`, `SLOT_COST`, `ZONE_WIDTH` (400px cashier zone) |
| `input.lua` | Polls keyboard each frame; A/D or arrows = move, E = pick up/down, F = interact |
| `game_state.lua` | Holds store, player, currency; survives scene switches |
| `player.lua` | Moves left/right into cashier zone; holds one item; 4-frame walk animation (idle/walk × no-held/held); `speed` property upgradeable via shop |
| `slot.lua` | One store cell; positions its item every frame |
| `store.lua` | Array of slots; `slot_at(x)`, `grow()`, `draw_bubbles()` for high-priority bubble rendering |
| `customer.lua` | Cashier zone NPC; walks in, waits with speech bubble, walks out after sale; state machine: idle → walking_in → waiting → walking_out |

### Items (`lua/game/items/`)

| File | What it does |
|------|-------------|
| `item.lua` | Base class for all carriable objects; `carriable = true`, `sellable = true`, `name = "Item"` by default |
| `watering_can.lua` | interact() waters the plant in the active slot |
| `pc_store.lua` | interact() opens BuyScene; blocked if player is holding anything; `sellable = false` |
| `plant.lua` | 6 types, 3 stages each; per-type cooldown and stage colors from `plant_data`; yellow bubble via `draw_bubble()` (rendered at high priority so it's never covered) |
| `grafter.lua` | Clones a stage-3 plant (resets original to stage 1, stores clone); places clone into empty slot on E; renders clone above itself when loaded |
| `sell_bin.lua` | Sell station; F while holding any sellable item sells it for currency |

### Scenes (`lua/game/scenes/`)

| File | What it does |
|------|-------------|
| `store_scene.lua` | Main loop — player moves, camera follows on x, pick up/interact handled here; cashier zone logic; context HUD bottom-left (HOVER/E/F labels); layered draw order for wall/bubbles |
| `buy_scene.lua` | Carousel UI — 9 items (6 plants + Watering Can + Grafter + Expand Slot); A/D cycle, F buy, E cancel; per-type price and preview color |

### Data (`lua/game/data/`)

| File | What it does |
|------|-------------|
| `plant_data.lua` | Per-type name, buy cost, sell value, cooldowns, and 3-stage color palette for all 6 plant types |

---

## Key Numbers

| Thing | Value |
|-------|-------|
| Base unit `U` | 20px |
| Slot size | 10U × 10U (200×200) |
| Player size | 6U × 12U (120×240) |
| All items | 6U × 6U (120×120) |
| Initial slots | 8 |
| Player speed | 220 px/s (base); upgradeable to 320 / 480 / 720 |
| Camera lerp | 0.85 (smooth follow on x, locked y) |
| Cashier zone width | 20U (400px), 2 slots wide, at x = -400 to 0 |
| Customer walk speed | 80 px/s |
| Customer spawn interval | 3–6s (testing); intended 15–30s |

---

## Controls

| Key | Action |
|-----|--------|
| A / ← | Move left |
| D / → | Move right |
| E | Pick up / put down |
| F | Interact (water, open shop) |
| Escape | Quit |

---

## Full Loop

1. Walk to slot 3 (PC) with empty hands → F to open shop
2. F to buy → plant appears in your hand
3. E over an empty slot → place plant
4. Walk to slot 1 → E to pick up watering can
5. Walk back to plant slot → wait for bubble (3s)
6. F → waters plant, bubble disappears, stage advances
7. Repeat for stage 2 (5s cooldown)
8. Stage 3 = done, no more bubble

---

## Up Next

*(nothing planned — add a new steps file)*

## Cut / Not Yet Built

- Real sprites (all rectangles; cashier wall uses placeholder canvas until `assets/cashier_wall.png` is provided)
- Win condition or idle loop
- Customer patience timer (customer never leaves until served)
