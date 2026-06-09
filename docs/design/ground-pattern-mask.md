# Design: Ground Pattern Mask

## Goal

Apply a repeating pattern texture to the cashier floor tiles the same way `WallPattern` does for the wall — using a red-mask PNG and a world-space GLSL shader so the pattern tiles seamlessly across the floor regardless of camera position.

## How the Wall Pattern Works (Reference)

- `cashier_wall.png` is a single large image drawn at `(-ZONE_WIDTH, 0)`.
- Pixels that are pure red (`r > 0.9, g < 0.1, b < 0.1`) act as a mask.
- `wall_pattern.glsl` replaces those pixels with the repeating pattern from `wall_pattern.png`, sampled at world coordinates, so it stays aligned as the camera pans.
- Caller passes `world_origin` (the tile's top-left in world space) so the shader can compute `world_pos = world_origin + uv * tile_size`.

## What Changes

### New asset: `assets/images/ground_pattern.png`
A repeating texture the user supplies (analogous to `wall_pattern.png`). Registered in `assets.lua` as `A.ground_pattern` via `try_img` so the feature degrades gracefully if the file isn't there yet.

### New asset (mask): `assets/images/slot.png` — updated by user
The existing `slot.png` tile gets red mask pixels where the pattern should show through. **No code change needed here — this is a pixel-art edit the user makes.**  
If the user wants a separate masked tile (e.g. to keep `slot.png` clean), they can supply `assets/images/slot_masked.png`; we add that as `A.slot_masked` via `try_img` and fall back to `A.slot`.

### New shader: `assets/shaders/ground_pattern.glsl`
Nearly identical to `wall_pattern.glsl`. The mask check can be the same red-pixel test. The only difference from the wall shader is cosmetic naming — reusing the wall shader directly is also fine since the logic is identical.

### New Lua wrapper: `lua/game/shaders/ground_pattern.lua`
Mirrors `wall_pattern.lua`:
```lua
apply(pattern_img, world_x, world_y, tile_img)
clear()
```

### Modified: `lua/game/scenes/store_scene.lua`

`_cashier_floor` draw loop becomes:

```lua
local tile_img = A.slot_masked or A.slot
while fx < 0 do
    if A.ground_pattern then
        GroundPattern.apply(A.ground_pattern, fx, floor_y, tile_img)
    end
    love.graphics.draw(tile_img, fx, floor_y, 0, sx, sy)
    if A.ground_pattern then GroundPattern.clear() end
    fx = fx + slot_w
end
```

`world_origin` is `{fx, floor_y}` each iteration — this is what keeps the pattern seamlessly aligned across tiles in world space.

## What Stays the Same

- `WallPattern` and the wall draw path — untouched.
- `slot.png` remains the default tile; the masked variant is opt-in.
- The shader API pattern (`apply` / `clear`) is unchanged.
- Floor position (`floor_y`, `slot_w`, scales) unchanged.

## Open Questions

1. **Separate pattern file or reuse `wall_pattern.png`?** A dedicated `ground_pattern.png` lets the wall and floor have different textures. Reusing the same file is simpler if you want them to match.
2. **Reuse `wall_pattern.glsl` directly or duplicate?** The GLSL is identical; a second file is only needed if the ground mask color or blend logic will differ later.
3. **New masked tile or edit `slot.png` in-place?** Editing `slot.png` is simpler; a separate `slot_masked.png` keeps the original clean.
