## Goal

Add a headless game-design test file (`tests/test_balance.lua`) containing five observational balance/pacing tests. These tests are not pass/fail unit tests — they run a simulated game loop and print human-readable results that a designer can read to evaluate balance. They share the headless runner infrastructure already used by `tests/test_basics.lua` and `tests/test_golden_lotus.lua`.

---

## Affected files

- `tests/test_balance.lua` — new file; all five tests live here
- `lua/headless/runner.lua` — may need a `fast_forward_until` helper added (currently it lives inline in `test_golden_lotus.lua`)
- `lua/headless/stubs.lua` — no changes expected; already handles headless graphics

---

## What changes

### New file: `tests/test_balance.lua`

A single test file containing all five balance probes. Each probe:
1. Calls `runner.setup()` to get a fresh `{ gs, input, sm }` context.
2. Mutates `gs` fields directly where needed (currency, unlocked_plants, growth_mult, speed_level, store slots) to set up the scenario without navigating the buy UI.
3. Runs the simulation loop via `runner.tick()` and/or `fast_forward_until()`.
4. Prints a labelled result line — never `assert`s a specific value (these are observational).

---

### Test 1 — Progression pace

**What it measures:** From a $0 cold-start with only grass unlocked, how many simulated seconds until the player can first afford each plant type?

**State setup:**
- `ctx.gs.currency = 0`
- `ctx.gs.unlocked_plants = { [1] = true }` (default, but explicit)
- One grass plant pre-planted in slot 4 (the first plant slot after the three tool slots), already at stage 1.
- The watering-can is in slot 1 as normal. The player loops: walk to watering can, pick it up, walk to plant slot, water when ready, walk to cashier zone, sell to first matching customer.

**Simulation approach:**
- Reuse the `walk_to` + `fast_forward_until` + `sell_plant` helpers from `test_golden_lotus.lua` (see note below on extracting helpers).
- For each target plant (cactus=$3, rose=$6, tulip=$10, daisy=$15, golden lotus=$20), `fast_forward_until` `ctx.gs.currency >= cost`.
- Record `elapsed` at each threshold.

**Output:**
```
[balance] progression pace (cold start, grass only):
  cactus    first affordable at  X.X s
  rose      first affordable at  X.X s
  tulip     first affordable at  X.X s
  daisy     first affordable at  X.X s
  golden lotus first affordable at  X.X s
```

---

### Test 2 — Gold-per-minute per plant

**What it measures:** For each plant type, how much gold does a single plant earn per simulated minute under ideal play (water immediately when ready, sell every matching customer with no delay)?

**State setup (per plant type, run separately):**
- `ctx.gs.currency = 999999` (effectively infinite, so we measure income not spend)
- `ctx.gs.unlocked_plants = { [pt] = true }` for the plant under test.
- Plant of type `pt` pre-planted in slot 4 at stage 1.
- `math.randomseed(42)` for deterministic customer spawns.

**Simulation approach:**
- Record `start_currency`.
- Run for 60 simulated seconds (60 × 60 ticks at dt=1/60, or equivalent large-dt ticks).
- Record `end_currency`. GPM = `(end_currency - start_currency) / 1` (already per minute).
- The "perfect loop" means: use `fast_forward_until` to detect `plant.ready`, immediately press interact to water; use `fast_forward_until` to detect `customer:arrived()` with matching plant type, immediately sell.

**Complication:** The customer spawn timer uses `math.random(3,6)` so results vary with seed. Seeding `math.randomseed(42)` at the start of each sub-test gives a deterministic but realistic cadence.

**Output:**
```
[balance] gold-per-minute (perfect loop, 60 s window, seed 42):
  grass        X.X g/min   (sell=$5,  cooldowns=1+1)
  cactus       X.X g/min   (sell=$8,  cooldowns=8+12)
  rose         X.X g/min   (sell=$13, cooldowns=6+9)
  tulip        X.X g/min   (sell=$20, cooldowns=4+7)
  daisy        X.X g/min   (sell=$28, cooldowns=3+5)
  golden lotus X.X g/min   (sell=$40, cooldowns=2+3)
```

---

### Test 3 — Grafter ROI

**What it measures:** If the player buys a grafter and clones a golden lotus into a second slot, at what simulated time does the cloned plant's cumulative earnings exceed the cost of buying a second golden lotus outright ($20)?

**State setup:**
- Two parallel contexts share the same seed and scenario except for the item in slot 5:
  - **Context A (grafter):** golden lotus in slot 4 (at stage 3 so it can be cloned), grafter held by player, second slot (slot 5) empty. Clone is placed into slot 5 at time 0.
  - **Context B (bought):** golden lotus in slot 4 (stage 3), a second fresh golden lotus (stage 1) purchased and placed in slot 5 at time 0.
- Both contexts start with the same `currency` baseline.
- `math.randomseed(42)`.

**Grafter cost:** The grafter has `cost = 0` in `buy_scene.lua` currently — the test should document this and note that the ROI question only makes sense once the grafter has a real cost. The test should read `CATALOGUE` or hardcode a `GRAFTER_COST` constant at the top so a designer can easily change it.

**Simulation approach:**
- Run both contexts in lockstep tick by tick.
- Track `cumulative_earnings_A` and `cumulative_earnings_B` by watching `ctx.gs.currency` changes.
- `fast_forward_until` the earnings delta (A earns more from the second slot than B has earned from the second slot, offset by the $20 alternative cost).

**Output:**
```
[balance] grafter ROI vs buying second golden lotus ($20):
  grafter cost (as configured): $0
  cloned plant breakeven: X.X s  (or "never" if grafter cost = 0)
  note: grafter cost is currently 0 — set GRAFTER_COST in test to model a real cost
```

---

### Test 4 — Growth multiplier value

**What it measures:** Over a fixed 5-minute (300 s) window, how much extra gold does each growth multiplier tier earn over the base (1.0)? At what simulated time does the tier pay for itself?

**State setup (per tier, run separately):**
- `ctx.gs.growth_mult = mult` (1.0, 1.25, 1.60, 2.00) set directly — no UI navigation needed.
- `ctx.gs.growth_level` set to match (0, 1, 2, 3).
- Golden lotus in slot 4 at stage 1.
- `math.randomseed(42)`.

**Simulation approach:**
- Run each scenario for 300 simulated seconds.
- Record total gold earned.
- Extra gold vs 1.0 = `gold_at_mult - gold_at_1.0`.
- Payback time: find the simulated second at which `cumulative_extra_gold >= tier_cost`.

**Tier costs** (from `growth_tiers.lua`): tier 1 = $20, tier 2 = $50, tier 3 = $100.

**Output:**
```
[balance] growth multiplier value (golden lotus, 300 s, seed 42):
  mult 1.00 (base):  XXX g total,    +0 extra
  mult 1.25 ($20):   XXX g total,  +XX extra,  payback at XX.X s
  mult 1.60 ($50):   XXX g total,  +XX extra,  payback at XX.X s
  mult 2.00 ($100):  XXX g total,  +XX extra,  payback at XX.X s
```

---

### Test 5 — Speed upgrade ROI

**What it measures:** Customers served per simulated hour at each player speed tier.

**What speed tier actually controls:** Player movement speed (px/s): base=220, tier1=320, tier2=480, tier3=720. The customer spawn timer (`math.random(3,6)`) is independent of speed tier — the bottleneck being measured is how quickly the player can physically walk between the watering-can, the plant slot, and the cashier zone to complete each cycle.

**State setup (per tier):**
- `ctx.gs.speed_level = tier`; `ctx.gs.player.speed = SPEED_TIERS[tier].speed` (or `220` for base).
- Golden lotus in slot 4 at stage 1.
- `math.randomseed(42)`.

**Simulation approach:**
- Run for 3600 simulated seconds.
- Count `sales` by hooking into `ctx.gs.currency` delta: each sale adds $40 (golden lotus sell value); increment counter whenever currency increases.
- Also measure total gold earned as a cross-check.

**Output:**
```
[balance] speed upgrade ROI (golden lotus, 3600 s, seed 42):
  tier 0 (base, $0,   speed=220): XX sales/hour,  XXXX g
  tier 1 ($15,        speed=320): XX sales/hour,  XXXX g,  payback at ~XX min
  tier 2 ($40,        speed=480): XX sales/hour,  XXXX g,  payback at ~XX min
  tier 3 ($100,       speed=720): XX sales/hour,  XXXX g,  payback at ~XX min
```

---

## What stays the same

- `runner.setup()`, `runner.tick()`, `runner.run()` — no changes to their signatures.
- `stubs.lua` — no changes needed.
- `test_basics.lua` — untouched.
- All game logic files — tests only read/set state directly, they do not patch game logic.
- The test runner invocation pattern: `love . --headless tests/test_balance.lua`.

---

## Helper extraction note

The `walk_to`, `fast_forward_until`, and `sell_plant` helpers are currently defined inline in `test_golden_lotus.lua`. The balance tests need the same helpers. Two options:

**Option A (recommended for now):** Promote `fast_forward_until` into `runner.lua` as `runner.fast_forward_until(ctx, condition_fn, elapsed, cap)`. Leave `walk_to` and `sell_plant` as local functions defined at the top of `test_balance.lua`, since they require a `ctx` and may need slight variation per test.

**Option B:** Create `lua/headless/test_helpers.lua` with all three helpers. Only worth doing if a third test file needs them.

The checklist agent should pick one option; Option A is preferred as it adds the most-reused helper (`fast_forward_until`) to the right layer without over-engineering a helpers module.

---

## Open questions

1. **Grafter cost is $0.** The ROI test (Test 3) is vacuous until the grafter has a real cost. Should we pick a placeholder cost (e.g. $30) for the test, or just print a note and move on? Recommendation: hardcode a `GRAFTER_COST = 30` constant at the top of the test file with a comment, so a designer can read the output meaningfully while the game cost is still TBD.

2. **Speed tier and customer throughput.** Inspecting `store_scene.lua`: the customer spawn timer is `math.random(3, 6)` seconds and does not scale with speed tier. This means at high speed the player may be waiting at the cashier zone for customers more often than walking. The test will reveal whether speed meaningfully changes customers-per-hour or whether the bottleneck is spawn rate, not movement. The designer should interpret these results in that light.

3. **Plant-watering automation.** Tests 2–5 require "water immediately when ready." The watering-can interaction requires the player to be standing at the right slot. The test will use `walk_to` + `fast_forward_until(plant.ready)` + interact. If the plant grows while the player is at the cashier zone, the test may miss a water cycle. This is acceptable — it reflects realistic play and gives a slightly conservative GPM estimate. No special handling is needed.

4. **Simulation window for Test 5.** 3600 simulated seconds (1 hour) at dt=1.0 ticks means at most 3600 loop iterations — fast enough. But the customer spawn timer means very few customers arrive in a short window. Confirm 3600 s gives enough sales (expected: ~100–300 sales/hour for fast plants) to produce meaningful per-tier differences.
