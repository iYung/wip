# Player Speed Sprite Swapping

Change the player character images based on the current speed upgrade level.

## Overview

There are 4 speed levels (0–3) and 4 sprite states per level:
- `player_idle`
- `player_walk`
- `player_idle_held`
- `player_walk_held`

That's **16 images total** (4 new sets, replacing the current 1 set).

---

## Steps

### 1. Create new image assets

For each speed level, create a set of 4 PNGs at the same dimensions (120×240):

| Level | Files |
|-------|-------|
| 0 (base) | `player_idle.png`, `player_walk.png`, `player_idle_held.png`, `player_walk_held.png` |
| 1 | `player_spd1_idle.png`, `player_spd1_walk.png`, `player_spd1_idle_held.png`, `player_spd1_walk_held.png` |
| 2 | `player_spd2_idle.png`, `player_spd2_walk.png`, `player_spd2_idle_held.png`, `player_spd2_walk_held.png` |
| 3 | `player_spd3_idle.png`, `player_spd3_walk.png`, `player_spd3_idle_held.png`, `player_spd3_walk_held.png` |

Place all files in `assets/`.

> **Do not modify the existing base-level files** (`player_idle.png`, `player_walk.png`, `player_idle_held.png`, `player_walk_held.png`). Only add the new `spd1`/`spd2`/`spd3` variants.

---

### 2. Load all images in `assets.lua`

In `lua/game/assets.lua`, add loads for the 12 new images alongside the existing 4:

```
A.player_spd1_idle       = img("player_spd1_idle.png")
A.player_spd1_walk       = img("player_spd1_walk.png")
A.player_spd1_idle_held  = img("player_spd1_idle_held.png")
A.player_spd1_walk_held  = img("player_spd1_walk_held.png")
-- repeat for spd2, spd3
```

---

### 3. Build sprite sets for each speed level in `player.lua`

Currently one `SpriteSet` is created at init. Instead, build a table of 4 `SpriteSet`s (one per speed level) using the matching images. Store them as `self.sprite_sets[0..3]`.

---

### 4. Add a helper to swap the active sprite set

Add `Player:set_speed_level(level)` that:
1. Stores the new level.
2. Swaps `self.sprite` to `self.sprite_sets[level]`.

The rest of the player code (movement, draw) already calls `self.sprite`, so no other changes are needed there.

---

### 5. Call the helper when a speed upgrade is purchased

In `lua/game/scenes/buy_scene.lua`, after `gs.speed_level` is incremented (around line 112), call:

```
gs.player:set_speed_level(gs.speed_level)
```

---

### 6. Initialize correctly on game load

In `player.lua`'s `Player:new()`, after building the sprite sets, call `self:set_speed_level(0)` so the default set is active. If the game ever saves/loads speed level, call the helper during load as well.
