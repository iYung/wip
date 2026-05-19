# Golden Lotus Timing Checklist

- [x] Task 1 — `tests/test_golden_lotus.lua` *(new file)* — Implement the full timing
  test as specified in `docs/design/golden-lotus-timing.md`. The file must:

  **Helpers (local functions at the top):**
  - `walk_to(ctx, target_x, elapsed)` — each iteration: if `ctx.gs.player.x < target_x`
    hold `"move_right"` and release `"move_left"`, else hold `"move_left"` and release
    `"move_right"`; call `runner.tick(ctx.input, ctx.sm, 1, 1/60)`; add `1/60` to
    elapsed; stop when `math.abs(ctx.gs.player.x - target_x) <= 5`. Release both
    directions before returning. Returns updated elapsed.
  - `fast_forward_until(ctx, condition_fn, elapsed)` — loop: if `condition_fn()` is
    true return elapsed; otherwise call `runner.tick(ctx.input, ctx.sm, 1, 1.0)` and
    add `1.0` to elapsed. Must also stop after a safety cap (e.g. 600 iterations /
    600 simulated seconds) and error with a descriptive message so the test never
    hangs.
  - `sell_plant(ctx, plant_type, elapsed)` — loop until sale made:
    - Wait (using `fast_forward_until`) for `ctx.sm.current._customer:arrived()`.
    - If `ctx.sm.current._customer.plant_type ~= plant_type`: press `"pick_up_down"`,
      tick 1 frame, add `1/60` to elapsed, continue loop.
    - Otherwise: while not `ctx.sm.current._customer:on_last_message()`, advance
      dialog — first fast-forward until `ctx.sm.current._customer:line_complete()`,
      then press `"interact"` and tick 1 frame (add `1/60`). After all messages are
      done, press `"interact"` once more and tick 1 frame (the sale). Return elapsed.

  **Setup:**
  ```lua
  math.randomseed(42)
  local runner     = require("lua/headless/runner")
  local StoreScene = require("lua/game/scenes/store_scene")
  local ctx = runner.setup(function(gs, input, sm)
      return StoreScene.new(gs, input, sm)
  end)
  ctx.gs.currency = 10
  local elapsed = 0
  ```

  **Grass cycles (repeat 3 times using a for loop):**
  Each iteration must execute in order:
  1. `walk_to(ctx, 500)` — PC Store slot
  2. `ctx.input:press("interact")` + tick 1 frame — opens BuyScene
  3. `ctx.input:press("interact")` + tick 1 frame — buys Grass (index 1, selected by
     default); BuyScene switches back to StoreScene and player now holds Plant(grass)
  4. `walk_to(ctx, 700)` — slot 4
  5. `ctx.input:press("pick_up_down")` + tick 1 frame — puts down plant
  6. `walk_to(ctx, 100)` — slot 1 (watering can)
  7. `ctx.input:press("pick_up_down")` + tick 1 frame — picks up watering can
  8. `walk_to(ctx, 700)` — slot 4
  9. `fast_forward_until(ctx, function() return ctx.gs.store.slots[4].item and ctx.gs.store.slots[4].item.ready end)`
  10. `ctx.input:press("interact")` + tick 1 frame — waters to stage 2
  11. `fast_forward_until` same condition — waits for stage-2 cooldown
  12. `ctx.input:press("interact")` + tick 1 frame — waters to stage 3
  13. `walk_to(ctx, 100)` — slot 1
  14. `ctx.input:press("pick_up_down")` + tick 1 frame — puts down watering can
  15. `walk_to(ctx, 700)` — slot 4
  16. `ctx.input:press("pick_up_down")` + tick 1 frame — picks up stage-3 plant
  17. `walk_to(ctx, -200)` — cashier zone
  18. `elapsed = sell_plant(ctx, 1, elapsed)`

  After the loop: `assert(ctx.gs.currency >= 20, ...)`

  **Golden Lotus cycle:**
  1. `walk_to(ctx, 500)` — PC Store
  2. `ctx.input:press("interact")` + tick 1 — opens BuyScene
  3. Press `"move_right"` 5 times (one press + tick per press) to reach catalogue
     index 6 (Golden Lotus)
  4. `ctx.input:press("interact")` + tick 1 — buys Golden Lotus ($20); player now
     holds Plant(golden_lotus)
  5. `walk_to(ctx, 700)` — slot 4
  6. `ctx.input:press("pick_up_down")` + tick 1 — puts down plant
  7. `walk_to(ctx, 100)` — slot 1
  8. `ctx.input:press("pick_up_down")` + tick 1 — picks up watering can
  9. `walk_to(ctx, 700)` — slot 4
  10. `fast_forward_until` for `slots[4].item.ready`
  11. `ctx.input:press("interact")` + tick 1 — waters to stage 2
  12. `fast_forward_until` for `slots[4].item.ready`
  13. `ctx.input:press("interact")` + tick 1 — waters to stage 3
  14. `walk_to(ctx, 100)` — slot 1
  15. `ctx.input:press("pick_up_down")` + tick 1 — puts down watering can
  16. `walk_to(ctx, 700)` — slot 4
  17. `ctx.input:press("pick_up_down")` + tick 1 — picks up Golden Lotus
  18. `walk_to(ctx, -200)` — cashier zone
  19. `elapsed = sell_plant(ctx, 6, elapsed)` — handles The Collector's 3-line dialog

  **Assertions and output:**
  ```lua
  assert(ctx.gs.currency > 10, "currency should have increased from sales")
  print(string.format("Golden Lotus sold in %.1f simulated seconds", elapsed))
  print("PASS: golden lotus timing")
  ```
