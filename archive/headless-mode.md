## Headless Mode Checklist

Tasks are ordered so that dependencies come first. Tasks marked **sequential** must
complete before the tasks that depend on them. All other tasks in the same tier can
run in parallel.

---

### Tier 1 — Foundation (must run first; everything else depends on this)

- [x] Task 1 — `conf.lua` — Add headless detection at the top of the file: loop over
  `arg or {}`, set a local `headless` flag when `--headless` is found, then extend
  `love.conf(t)` to disable the window (`t.window.width = 1`, `t.window.height = 1`)
  and set `t.modules.window`, `.graphics`, `.audio`, `.sound`, `.joystick`, `.touch`,
  and `.video` all to `false` when the flag is true. Normal (non-headless) conf values
  are unchanged.

- [x] Task 2 — `lua/headless/stubs.lua` *(new file)* — Create the stubs module that
  installs no-op replacements into the `love` global before any game module loads.
  Must cover:
  - `love.graphics`: install a catch-all `__index` metatable that returns a no-op
    function for unknown keys; functions whose name starts with `"new"` return a
    lightweight stub image table with `getWidth()`, `getHeight()`, `getDimensions()`,
    and `setFilter()` (all returning safe values or no-ops). Explicit stubs for
    `setDefaultFilter`, `setCanvas`, `setColor`, `setShader`, `setBlendMode`,
    `setFilter`, `draw`, `rectangle`, `print`, `printf`, `push`, `pop`, `translate`,
    `scale`, `clear`, `getFont`, `getDimensions`.
  - `love.keyboard`: stub `isDown` returning `false`.
  - `love.filesystem`: stub `getInfo` returning `nil` so `try_img` silently skips
    optional assets.
  - After stubbing graphics, set `package.loaded["lua/game/assets"] = nil` so
    `assets.lua` is re-required through the stubbed `love.graphics` (forcing
    `newImage` calls to hit the stub instead of the real GPU path).

---

### Tier 2 — Scriptable input and test runner (can run in parallel; both depend on Tier 1 stubs existing)

- [x] Task 3 — `lua/headless/input.lua` *(new file)* — Implement the `HeadlessInput`
  class. Must satisfy the same interface as `lua/core/input.lua` (`is_down(action)`,
  `pressed(action)`, `update()`). Internal state is driven entirely by test calls,
  not by `love.keyboard.isDown`. API:
  - `HeadlessInput.new()` — creates instance with empty `_down` and `_pressed` tables
  - `HeadlessInput:press(action)` — marks action as both down and pressed for the next
    `update()` call, then clears pressed afterward
  - `HeadlessInput:hold(action)` — marks action as down but not pressed (simulates a
    key held across multiple frames)
  - `HeadlessInput:release(action)` — clears action from down
  - `HeadlessInput:update()` — promotes queued press state into `_pressed`, advances
    frame; called once per tick by the runner

- [x] Task 4 — `lua/headless/runner.lua` *(new file)* — Implement the test runner.
  Required API:
  - `runner.setup(scene_factory)` — creates a fresh `GameState`, a `HeadlessInput`
    instance, and a `SceneManager`; wires them together; calls `scene_manager:switch`
    with either `StartScene.new(gs, input, sm)` (default) or the result of calling
    the optional `scene_factory(gs, input, sm)`. Returns `{ gs, input, sm }`.
  - `runner.tick(input, scene_manager, n, dt)` — loops `n` times (default `n=1`,
    default `dt=1/60`): calls `input:update()` then `scene_manager:update(dt)`.
  - `runner.run(test_file)` — loads and executes `test_file` via `dofile` (or
    `require`) inside a `pcall`; prints pass/fail for each assertion; after all tests
    finish calls `love.event.quit(0)` if all passed or `love.event.quit(1)` on
    failure.

---

### Tier 3 — Entry-point wiring (depends on Tier 1 stubs and Tier 2 runner)

- [x] Task 5 — `main.lua` — Add headless detection at the very top of the file (before
  any `require` or `love.graphics` call): loop over `arg or {}` to set `headless` and
  capture `test_file` (the first non-flag argument after `--headless`). When
  `headless` is true: `require("lua/headless/stubs")`, then
  `require("lua/headless/runner").run(test_file)`, then `love.event.quit(0)`, then
  `return` — so the rest of `main.lua` (normal load/update/draw) is never reached.
  The normal path below the guard is completely unchanged.

---

### Tier 4 — First test file (depends on Tiers 1–3 all being complete)

- [x] Task 6 — `tests/test_basics.lua` *(new file)* — Write the first test file.
  Must include at minimum:
  - A `runner.setup()` call with no factory; assert `gs.currency == 1000` (initial
    currency check).
  - A second `runner.setup(factory)` call that starts directly in `StoreScene`;
    call `input:hold("move_right")` then `runner.tick(input, sm, 30)`; assert
    `gs.player.x` is greater than its initial value (player moved right).
  - Uses plain `assert` for all assertions so failures surface as Lua errors caught
    by `runner.run`.
  - The file must be self-contained: it `require`s `lua/headless/runner` and any
    scene modules it uses directly; it does not depend on test framework globals.
