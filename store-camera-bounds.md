# Store Scene Camera Bounds

## Problem

The camera follows the player on x with no bounds. At the extremes:
- **Far left** (cashier zone): left half of screen is empty — nothing exists beyond x = -400
- **Far right** (last slot): right half is empty — nothing exists beyond x = store:width()

## World Dimensions

| Thing | Value |
|-------|-------|
| World left edge | x = -400 (ZONE_WIDTH) |
| World right edge | x = store:width() = n × 200 |
| Screen width | 1280px (half = 640) |
| Initial store (7 slots) | 1400px → world total = 1800px |

**Note:** The world (1800px) is wider than the screen (1280px) from the start, so clamping is active immediately with no fallback needed.

## Solution: Clamp + Center Fallback

After the camera follows the player, clamp `camera.x` so neither edge goes past the world boundary. When the world is narrower than the screen, center the world instead.

```lua
local half_w     = 640
local world_left  = -ZONE_WIDTH          -- -400
local world_right = gs.store:width()     -- n × 120

if world_right - world_left > 1280 then
    -- world wider than screen: clamp both edges
    local min_x = world_left  + half_w   -- left screen edge = world left
    local max_x = world_right - half_w   -- right screen edge = world right
    self.camera.x = math.max(min_x, math.min(max_x, self.camera.x))
else
    -- world fits on screen: lock to center
    self.camera.x = (world_left + world_right) / 2
end
```

### What this looks like at runtime

| Store size | World width | Behavior |
|------------|-------------|----------|
| 7 slots (start) | 1800px | Clamping active from the start |
| 8+ slots | 2000px+ | More room to follow before hitting bounds |

## Steps

### 1. Add the clamp in `StoreScene:update()`

In [store_scene.lua](lua/game/scenes/store_scene.lua), after the existing camera follow lines:

```lua
self.camera:follow(gs.player, CAMERA_LERP)
self.camera.y = CAMERA_Y
```

Add:

```lua
local half_w      = 640
local world_left  = -ZONE_WIDTH
local world_right = gs.store:width()
self.camera.x = math.max(world_left + half_w, math.min(world_right - half_w, self.camera.x))
```

`ZONE_WIDTH` is already in scope (required at top of file).

### 2. No art changes needed

The store background rectangle already fills the slot area. The cashier zone background fills the left. Camera clamping means neither gap is ever visible.
