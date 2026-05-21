# Sway Shader

## Goal

Add a gentle sway (breeze) animation to the `store_bg_mid` and `store_bg_near` parallax background layers. The far layer stays static — distant scenery doesn't visibly sway. The effect should read as a light wind passing through foliage or grass in the background.

## Affected files

- `assets/shaders/sway.glsl` — new GLSL fragment shader
- `lua/game/shaders/sway.lua` — new Lua wrapper (same pattern as `wall_pattern.lua`)
- `lua/game/scenes/store_scene.lua` — require sway, accumulate `_sway_time` in `update()`, apply shader around mid/near draws
- `architecture.md` — document the new Sway shader

## What changes

**GLSL (`sway.glsl`)**
Fragment shader that displaces UV.x by a sine wave driven by UV.y (vertical position) and time. Externs:
- `float time` — accumulated seconds, drives animation
- `float amplitude` — how far UV shifts (small values like 0.004–0.008); controls per-layer intensity

Effect: `uv.x += sin(uv.y * 3.0 + time * 0.6) * amplitude`

Sampling the shifted UV creates a horizontal warp that rolls up the image over time, giving the impression of swaying.

**Lua wrapper (`sway.lua`)**
- `apply(time, amplitude)` — sends externs, activates shader
- `clear()` — resets to default shader

**StoreScene**
- Add `self._sway_time = 0` in `_setup_store()`
- Accumulate in `update(dt)`: `self._sway_time = self._sway_time + dt`
- In `draw()`, wrap each mid/near layer draw with `Sway.apply` / `Sway.clear`:
  - mid (`p = 0.20`): amplitude `0.004`
  - near (`p = 0.45`): amplitude `0.007`

## What stays the same

- Far layer (`p = 0.05`) — drawn without any shader, unchanged
- All parallax offset/tiling logic unchanged
- Store wall, cashier wall, all other draw calls unchanged
- Shader wrapper pattern (apply/clear) unchanged

## Open questions

None — the effect parameters (amplitude, frequency, speed) are tunable constants; defaults above produce a gentle, readable breeze at normal gameplay zoom.
