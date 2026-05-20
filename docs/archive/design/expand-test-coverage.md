## Goal

Add deterministic unit and integration tests for the six high-priority untested game systems: plant growth, grafter (clone tool), selling to customers, customer scripts and triggers, the shop (buy scene), and item carrying. Each new test file in `tests/` exercises one area via the headless runner; no game-logic files are modified.

---

## Affected files

**New files**
- `tests/test_plant_growth.lua` — plant growth system unit tests
- `tests/test_grafter.lua` — grafter clone tool unit tests
- `tests/test_selling.lua` — cashier zone sale logic integration tests
- `tests/test_customer_scripts.lua` — scripted customer trigger, tracking, and cooldown tests
- `tests/test_shop.lua` — BuyScene purchase logic tests
- `tests/test_carrying.lua` — item pickup and put-down tests

**No changes to**
- All `lua/` game and headless files
- `tests/test_basics.lua`, `tests/test_golden_lotus.lua`, `tests/test_balance.lua`

---

## What changes

### `tests/test_plant_growth.lua`

Unit tests exercising `Plant` directly and via the watering-can interact path. Each test constructs a fresh `Plant.new(type)`, calls `runner.fast_forward_until` or `runner.tick` to advance time, and asserts state.

| Test name | What it verifies |
|-----------|-----------------|
| `plant: stage-1 cooldown triggers ready` | After ticking a Grass plant for its stage-1 cooldown (1 s), `plant.ready == true` and `plant.bubble.visible == true`. |
| `plant: stage-2 cooldown triggers ready` | Water Grass to stage 2, tick for its stage-2 cooldown (1 s), assert `ready == true`. |
| `plant: water advances stage 1→2` | Calling `plant:water()` on a ready stage-1 plant sets `plant.stage == 2`, `ready == false`, `bubble.visible == false`. |
| `plant: water advances stage 2→3` | Water to stage 2 readiness, call `plant:water()`, assert `plant.stage == 3`. |
| `plant: stage-3 plant is not ready and cannot be watered` | A stage-3 plant never sets `ready = true` regardless of time; calling `plant:water()` is a no-op (stage stays 3). |
| `plant: cooldowns match plant_data for all 6 types` | For each plant type 1–6: create `Plant.new(pt)`, tick exactly `PLANT_DATA[pt].cooldowns[1]` seconds, assert `ready == true`. Confirms `plant_data.lua` values are wired correctly. |
| `plant: stage3_counts incremented in StoreScene` | Full StoreScene context; water a plant in slot 4 to stage 3 via the watering-can interact path; assert `ctx.gs.stage3_counts[plant_type] == 1`. |

### `tests/test_grafter.lua`

Unit tests for `Grafter` behavior. Uses a StoreScene context so `_handle_interact` and `_handle_pick_up_down` are exercised.

| Test name | What it verifies |
|-----------|-----------------|
| `grafter: rejects stage-2 plant` | Hold the grafter, stand over a stage-2 plant, press `interact`; assert `grafter.loaded_plant == nil`. |
| `grafter: clones stage-3 plant` | Hold the grafter, stand over a stage-3 plant, press `interact`; assert `grafter.loaded_plant ~= nil` and `grafter.loaded_plant.plant_type == plant.plant_type`. |
| `grafter: source plant reset to stage 1 after clone` | After a successful clone, assert the original plant in the slot has `stage == 1`, `ready == false`. |
| `grafter: unload clears loaded_plant` | After loading, call `grafter:unload()`; assert `grafter.loaded_plant == nil`. |
| `grafter: place clone into empty slot` | With a loaded grafter, stand over an empty slot, press `pick_up_down`; assert the slot now contains a `Plant` with the correct `plant_type`, and `grafter.loaded_plant == nil`. |
| `grafter: cloned plant has correct type` | Clone a Cactus (type 2); assert `loaded_plant.plant_type == 2`. |

### `tests/test_selling.lua`

Integration tests for the cashier zone sale path. Tests set up a StoreScene context, move the player to `x < 0`, and trigger customers directly via `ctx.sm.current._customer:show(cfg)` to avoid waiting for the spawn timer.

| Test name | What it verifies |
|-----------|-----------------|
| `sell: correct plant type accepted, currency increases` | Hold a stage-3 Grass (type 1), show a Grass customer, advance through dialog, press `interact`; assert `gs.currency` increased by `PLANT_DATA[1].sell` (5). |
| `sell: wrong plant type not accepted` | Hold a stage-3 Cactus (type 2), show a Grass customer (type 1) in done_talking state; press `interact`; assert `gs.currency` unchanged and `player.held_item ~= nil`. |
| `sell: stage-1 plant not accepted` | Hold a stage-1 Grass, show a done_talking Grass customer; press `interact`; assert no sale occurs. |
| `sell: stage-2 plant not accepted` | Hold a stage-2 Grass, show a done_talking Grass customer; press `interact`; assert no sale occurs. |
| `sell: customer currency is direct sell value (not 2×)` | Sell a stage-3 Golden Lotus (type 6); assert `gs.currency` delta equals `PLANT_DATA[6].sell` (40), not 80. This documents and pins the current sell formula (`plant_sell_value` returns `pd.sell` for stage-3). |
| `sell: player held_item cleared after sale` | After a successful sale, assert `player.held_item == nil`. |
| `sell: customer enters serve state after sale` | After a successful sale, assert `customer.state == "walking_out"`. |

### `tests/test_customer_scripts.lua`

Tests for scripted customer spawning logic inside StoreScene. Uses `ctx.sm.current._next_customer_cfg()` directly where possible, and full ticking where the spawn timer must fire.

| Test name | What it verifies |
|-----------|-----------------|
| `scripts: scripted customer spawned when trigger met` | Set `gs.stage3_counts[1] = 1` (Old Pete chapter 1 trigger); call `scene:_next_customer_cfg()`; assert returned cfg has `id == "old_pete"` and `chapter == 1`. |
| `scripts: scripted customer not spawned before trigger count` | `gs.stage3_counts[1] = 0`; call `_next_customer_cfg()`; assert no scripted customer returned (falls back to random). |
| `scripts: chapter 2 not available before chapter 1 seen` | Set `gs.stage3_counts[2] = 3` (Old Pete ch2 trigger), `gs.seen_scripts = {}`; call `_next_customer_cfg()`; assert Old Pete chapter 2 is not returned. |
| `scripts: chapter 2 available after chapter 1 seen` | Set `gs.stage3_counts[2] = 3` and `gs.seen_scripts["old_pete:1"] = true`; call `_next_customer_cfg()`; assert Old Pete chapter 2 is returned. |
| `scripts: seen_scripts written on sale, not on spawn` | Spawn Old Pete ch1, serve him (complete sale); assert `gs.seen_scripts["old_pete:1"] == true`. |
| `scripts: seen_scripts not written on dismiss` | Spawn Old Pete ch1, dismiss him; assert `gs.seen_scripts["old_pete:1"]` is nil. |
| `scripts: dismiss sets cooldown` | Dismiss a scripted customer; assert `scene._script_cooldowns["old_pete:1"] == 3`. |
| `scripts: cooldown decrements per sale, customer returns after 3 sales` | Dismiss Old Pete (cooldown=3), make 3 grass sales to other customers; assert cooldown reaches 0 (entry removed from `_script_cooldowns`) and Old Pete is eligible again. |

### `tests/test_shop.lua`

Tests for `BuyScene._confirm()` logic. Tests construct a BuyScene directly (passing a StoreScene as `store_scene`) and call `scene:_confirm()` after setting `scene.selected`.

| Test name | What it verifies |
|-----------|-----------------|
| `shop: buy plant unlocks it` | Select a Cactus entry, set `gs.currency = 100`, call `_confirm()`; assert `gs.unlocked_plants[2] == true`. |
| `shop: buy plant deducts correct cost` | Buy Cactus ($3); assert `gs.currency` decreased by 3. |
| `shop: buy plant gives player the plant` | After buying, assert `gs.player.held_item` is a Plant with the correct `plant_type`. |
| `shop: cannot buy if insufficient currency` | Set `gs.currency = 0`, try to buy Cactus ($3); assert `gs.currency` unchanged and `gs.player.held_item == nil`. |
| `shop: speed upgrade cost and speed value` | Buy Sneakers (tier 1, $15); assert `gs.currency` decreased by 15, `gs.player.speed == 320`, `gs.speed_level == 1`. |
| `shop: growth upgrade cost and multiplier value` | Buy Heat Lamps (tier 1, $20); assert `gs.currency` decreased by 20, `gs.growth_mult == 1.25`, `gs.growth_level == 1`. |
| `shop: expand slot adds one slot` | Buy Expand Slot; assert `#gs.store.slots` increased by 1. |
| `shop: expand slot costs SLOT_COST` | Verify currency decremented by `config.SLOT_COST`. |
| `shop: cannot buy speed at max level` | Set `gs.speed_level = 3` (max); attempt speed purchase; assert `gs.speed_level` unchanged. |
| `shop: cannot buy growth at max level` | Set `gs.growth_level = 3` (max); attempt growth purchase; assert `gs.growth_level` unchanged. |

### `tests/test_carrying.lua`

Tests for pick-up / put-down mechanics in StoreScene.

| Test name | What it verifies |
|-----------|-----------------|
| `carry: pick up carriable item from slot` | Player stands over a slot with the watering can; press `pick_up_down`; assert `player.held_item` is the watering can and `slot.item == nil`. |
| `carry: put down held item into empty slot` | Player holds watering can and stands over an empty slot; press `pick_up_down`; assert `slot.item` is the watering can and `player.held_item == nil`. |
| `carry: cannot pick up non-carriable item` | `carriable = false` item (none currently — this verifies the guard path): set a plant's `carriable = false`; attempt pick-up; assert `player.held_item == nil`. |
| `carry: cannot put down into occupied slot` | Player holds watering can, slot already has a plant; press `pick_up_down`; assert `player.held_item` unchanged. |
| `carry: cannot open shop while holding item` | Player holds watering can; press `interact` while over PC Store; assert scene does not switch to BuyScene (PCStore.interact no-ops when player holds something). |
| `carry: held item sprite follows player position` | After picking up an item and ticking one frame, assert `player.held_item.sprite.x` is near `player.x - sprite.width/2`. |

---

## What stays the same

- All `lua/core/`, `lua/game/`, and `lua/headless/` files — no modifications.
- `runner.setup()`, `runner.tick()`, `runner.fast_forward_until()` — test files use the existing API.
- Existing test files (`test_basics.lua`, `test_golden_lotus.lua`, `test_balance.lua`) — untouched.
- The headless invocation pattern: `love . --headless tests/<file>.lua`.

---

## Open questions

1. **BuyScene constructor in tests.** `BuyScene.new` requires a `store_scene` argument (used only for `scene_manager:switch(self.store_scene)` on cancel/buy). For shop tests we can pass the StoreScene instance from `runner.setup`; no special changes needed, but this needs to be confirmed when writing test code.

2. **Direct `_next_customer_cfg()` access.** The customer-script tests call `ctx.sm.current:_next_customer_cfg()` — a private method. This is acceptable for tests (the method is just a Lua function on the scene table), but the naming convention should be documented in the checklist so task agents don't introduce a public wrapper unnecessarily.

3. **Spawn timer bypass.** Several `test_customer_scripts.lua` tests call `_next_customer_cfg()` directly rather than waiting for the spawn timer to fire. Tests that need to verify end-to-end spawning (e.g. cooldown-after-3-sales) should drive the full ticking loop rather than bypass the timer; the checklist agent should decide per-test which approach is appropriate.
