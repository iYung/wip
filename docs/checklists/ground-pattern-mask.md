# Checklist: Ground Pattern Mask

## Tasks

- [x] **1. Register `ground_pattern` asset** — `lua/game/assets.lua`
  Add `A.ground_pattern = try_img("assets/images/ground_pattern.png")` after the existing `wall_pattern` line. Use `try_img` so it degrades gracefully.
  **Note:** For now `ground_pattern.png` does not exist; we reuse `A.wall_pattern` in code, so this line is added as a future hook. See task 3.

- [x] **2. Create `lua/game/shaders/ground_pattern.lua`**
  New file, wraps `wall_pattern.glsl` directly (no new GLSL file). Exposes the same `apply(pattern_img, world_x, world_y, tile_img)` / `clear()` API as `wall_pattern.lua`.

- [x] **3. Update `_cashier_floor` draw loop** — `lua/game/scenes/store_scene.lua`
  - `require` the new `GroundPattern` wrapper at the top of the file.
  - In `_cashier_floor.draw`, wrap each tile draw with `GroundPattern.apply` / `GroundPattern.clear`, passing `A.ground_pattern or A.wall_pattern` as the pattern image and `{fx, floor_y}` as the world origin.
  - Guard the whole thing so it only runs when a pattern image is available.
