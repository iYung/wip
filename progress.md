# Progress

## What's Built

All 16 MVP steps are implemented and running.

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
| `config.lua` | Shared constants — `U = 20` (base pixel unit) |
| `input.lua` | Polls keyboard each frame; A/D or arrows = move, E = pick up/down, F = interact |
| `game_state.lua` | Holds store, player, currency; survives scene switches |
| `player.lua` | Moves left/right, holds one item, two-frame walk animation |
| `item.lua` | Base class for all carriable objects |
| `watering_can.lua` | interact() waters the plant in the active slot |
| `pc_store.lua` | interact() opens BuyScene; blocked if player is holding anything |
| `plant.lua` | Three stages, cooldown timer, yellow bubble when ready; bubble hidden at stage 3 |
| `slot.lua` | One store cell; positions its item every frame |
| `store.lua` | Array of slots; slot_at(x) returns slot under a world x position |

### Scenes (`lua/game/scenes/`)

| File | What it does |
|------|-------------|
| `store_scene.lua` | Main loop — player moves, camera follows on x, pick up/interact handled here |
| `buy_scene.lua` | Overlay UI — F to buy plant (goes into player's hand), E to cancel |

### Data (`lua/game/data/`)

| File | What it does |
|------|-------------|
| `plant_cooldowns.lua` | `[plant_type][stage] = seconds`; currently 3s / 5s (testing values) |

---

## Key Numbers

| Thing | Value |
|-------|-------|
| Base unit `U` | 20px |
| Slot size | 10U × 10U (200×200) |
| Player size | 6U × 12U (120×240) |
| All items | 6U × 6U (120×120) |
| Initial slots | 8 |
| Player speed | 220 px/s |
| Camera lerp | 0.85 (smooth follow on x, locked y) |

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

## Cut from MVP

- Currency and harvesting
- Grafter
- Plant types 2–6
- Selling
- Store growth (slot count fixed)
- Real sprites (all rectangles)
