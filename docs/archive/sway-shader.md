## Sway Shader Checklist

- [x] Task A — `assets/shaders/sway.glsl` — create the GLSL fragment shader; extern `float time` and `float amplitude`; distort UV.x by `sin(uv.y * 3.0 + time * 0.6) * amplitude` then sample the texture at the shifted UV and return the result multiplied by `color`

- [x] Task B — `lua/game/shaders/sway.lua` — create the Lua wrapper using the same pattern as `wall_pattern.lua`; `apply(time, amplitude)` sends both externs and calls `love.graphics.setShader(shader)`; `clear()` calls `love.graphics.setShader()`

- [x] Task C — `lua/game/scenes/store_scene.lua` — integrate sway into StoreScene: (1) `require` the sway shader at the top, (2) initialize `self._sway_time = 0` inside `_setup_store()`, (3) accumulate `self._sway_time = self._sway_time + dt` in `update()`, (4) in `draw()`, wrap only the mid (`p=0.20`) and near (`p=0.45`) layer draws with `Sway.apply(self._sway_time, amplitude)` / `Sway.clear()` — mid amplitude `0.004`, near amplitude `0.007`; far layer (`p=0.05`) is drawn without any shader

- [x] Task D — `architecture.md` — add a Sway shader section under the Shaders heading, documenting files, GLSL logic, API, and usage (applied to mid/near parallax layers in StoreScene with per-layer amplitude)
