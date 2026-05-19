# Design: Golden Lotus Timing Test

## Goal

Write `tests/test_golden_lotus.lua` — a headless simulation test that starts the game
with $10 gold and measures how many simulation-seconds it takes to work up to and
sell a Golden Lotus. The test uses full player interaction (navigation, buying,
watering, cashier zone) scripted via `HeadlessInput` and `runner.tick`.

---

## Affected files

- `tests/test_golden_lotus.lua` — new file, this is the only change

---

## What changes

A new test file that:

1. Sets up a `StoreScene` context via `runner.setup`, then immediately sets
   `gs.currency = 10` (overriding the default 1000).
2. Seeds `math.randomseed(42)` before setup for a fully reproducible RNG sequence.
3. Tracks a running `elapsed` counter (in simulated seconds) incremented every tick.
4. Executes the full economic path: three grass grow-and-sell cycles to reach ≥ $20,
   then one Golden Lotus cycle.
5. Prints the total elapsed simulation time and asserts the sale happened.

---

## What stays the same

All game logic, headless runner, HeadlessInput, and existing test files are untouched.

---

## Key game-mechanics facts the test must handle

### Store layout at start
Slot 1 (x≈100): Watering Can · Slot 2 (x≈300): Garbage Bin · Slot 3 (x≈500): PC Store · Slot 4+ (x≈700…): empty  
SLOT_WIDTH = 200 px · Player start x = 100 · Player base speed = 220 px/s

### BuyScene catalogue indices
1=Grass · 2=Cactus · 3=Rose · 4=Tulip · 5=Daisy · 6=Golden Lotus · (7–11 tools/upgrades)  
`move_right` navigates right; `interact` buys. Golden Lotus = index 6, so press `move_right` 5
times from the default selected index of 1.

### Plant growth
Grass cooldowns: 1 s + 1 s = 2 s total  
Golden Lotus cooldowns: 2 s + 3 s = 5 s total  
`plant.ready` flips true when the cooldown fires; `WateringCan:interact` (player presses
`interact` while holding the can over the slot) calls `plant:water()` and advances the stage.

### Scripted customer complications

**Old Pete (chapter 1)** triggers after `stage3_counts[grass] >= 1`, i.e. after the very
first grass reaches stage 3. He wants **Cactus** — which we cannot sell. The test must
dismiss him (press `pick_up_down` while in the cashier zone with him arrived), then wait
for the next random customer (who will always want Grass while only Grass is unlocked).

Old Pete receives a `DISMISS_COOLDOWN_SALES = 3` penalty on dismissal, so he cannot
reappear until 3 sales have been made. Those 3 sales are exactly the 3 grass sales, so
by the Golden Lotus phase his cooldown has expired.

**The Collector (chapter 1)** triggers after `stage3_counts[golden_lotus] >= 1`, which
fires the moment we water the Golden Lotus to stage 3. He wants **Golden Lotus** and has
3 lines of dialog. The test must advance through all three messages (each F press skips
reveal or advances; after the third press `done_talking` becomes true), then press F once
more while holding the stage-3 lotus to complete the sale.

**During the Golden Lotus wait**: Old Pete's cooldown has reached 0 by the time the Lotus
is grown, so both he and The Collector may qualify. With seed 42 the exact sequence is
deterministic; the test handles it correctly by using a `sell_plant(plant_type)` loop
that dismisses any customer not requesting the target type.

### Selling from the cashier zone
Player must be at `x < 0`. Random customers: `done_talking = true` from arrival (no
messages), so `on_last_message()` is immediately true — one F press sells. Scripted
customers require advancing through their messages first.

---

## Helper patterns the implementation should use

```
-- walk_to(ctx, target_x, elapsed)
--   Hold move_right or move_left each tick until player.x ≈ target_x.
--   Returns updated elapsed.

-- fast_forward_until(ctx, condition_fn, elapsed, max_dt)
--   Each tick use max_dt (default 1.0) until condition_fn() returns true.
--   Returns updated elapsed.

-- sell_plant(ctx, plant_type, elapsed)
--   Loop: wait for customer arrival, then either advance dialog+sell (if
--   customer.plant_type matches) or dismiss and loop again.
--   Returns updated elapsed.
```

---

## Test sequence (high-level pseudocode)

```
math.randomseed(42)
ctx = runner.setup(StoreScene factory)
ctx.gs.currency = 10
elapsed = 0

for cycle = 1, 3 do              -- grow and sell Grass three times
    walk_to(ctx, 500)             -- PC Store
    press interact                -- open BuyScene
    press interact                -- buy Grass (index 1, costs $1)
    walk_to(ctx, 700)             -- slot 4
    press pick_up_down            -- put down plant
    walk_to(ctx, 100)             -- slot 1
    press pick_up_down            -- pick up watering can
    walk_to(ctx, 700)             -- slot 4
    fast_forward until plant.ready
    press interact                -- water → stage 2
    fast_forward until plant.ready
    press interact                -- water → stage 3 (increments stage3_counts[1])
    walk_to(ctx, 100)             -- slot 1
    press pick_up_down            -- put down watering can
    walk_to(ctx, 700)             -- slot 4
    press pick_up_down            -- pick up stage-3 grass
    walk_to(ctx, -200)            -- cashier zone
    elapsed = sell_plant(ctx, 1, elapsed)   -- handles Old Pete dismiss on cycle 1
end

-- assert gs.currency >= 20
walk_to(ctx, 500)                 -- PC Store
press interact                    -- open BuyScene
press move_right x5               -- navigate to Golden Lotus (index 6)
press interact                    -- buy Golden Lotus (costs $20)
walk_to(ctx, 700)                 -- slot 4
press pick_up_down                -- put down plant
walk_to(ctx, 100)                 -- slot 1
press pick_up_down                -- pick up watering can
walk_to(ctx, 700)                 -- slot 4
fast_forward until plant.ready    -- 2 s
press interact                    -- water → stage 2
fast_forward until plant.ready    -- 3 s
press interact                    -- water → stage 3 (increments stage3_counts[6])
walk_to(ctx, 100)                 -- slot 1
press pick_up_down                -- put down watering can
walk_to(ctx, 700)                 -- slot 4
press pick_up_down                -- pick up Golden Lotus
walk_to(ctx, -200)                -- cashier zone
elapsed = sell_plant(ctx, 6, elapsed)   -- The Collector dialog + sale

print("Golden Lotus sold in " .. string.format("%.1f", elapsed) .. " simulated seconds")
assert gs.currency reflects lotus sale value
print("PASS: golden lotus timing")
```

---

## Output

```
Golden Lotus sold in X.X simulated seconds
PASS: golden lotus timing
```

The exact number is the output of interest — that's what the test is designed to surface.

---

## Open questions

None.
