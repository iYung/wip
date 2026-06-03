# Checklist: Customer Cooldown Upgrade

## Group A — Data & State (no dependencies)

- [x] **Create cooldown tiers data file** — `lua/game/data/cooldown_tiers.lua`: create new file returning a table of 3 entries `{ cost, cooldown }` mirroring `growth_tiers.lua` format: `{ cost = 10, cooldown = 3 }`, `{ cost = 25, cooldown = 2 }`, `{ cost = 50, cooldown = 0 }`

- [x] **Add `cooldown_level` to game state** — `lua/game/game_state.lua`: in `GameState.new()`, after `self.growth_level = 0`, add `self.cooldown_level = 0`

- [x] **Load ads icon table in assets** — `lua/game/assets.lua`: after the `A.heat_lamps` loop block (line 59), add an `A.ads = {}` loop that calls `try_img("assets/ads_" .. lvl .. ".png")` for `lvl = 1, 3`

---

## Group B — Store scene spawn logic (must follow Group A)

- [x] **Require cooldown tiers in store scene** — `lua/game/scenes/store_scene.lua`: at the top of the file alongside other `require` calls (after line 16 `local A = require(...)`), add `local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")`

- [x] **Add `spawn_cooldown` helper** — `lua/game/scenes/store_scene.lua`: after the `COOLDOWN_TIERS` require, define a module-level local function `spawn_cooldown(gs)` that returns `4` when `gs.cooldown_level == 0`, otherwise returns `COOLDOWN_TIERS[gs.cooldown_level].cooldown`

- [x] **Replace initial spawn timer (must follow previous two tasks)** — `lua/game/scenes/store_scene.lua`: in `_setup_store` at line 82, replace `Timer.new(math.random(3, 6))` with `Timer.new(spawn_cooldown(gs))`

- [x] **Replace timer reset in update (must follow `spawn_cooldown` helper task)** — `lua/game/scenes/store_scene.lua`: in `StoreScene:update`, replace the entire `if not self._customer:active() then` block (lines 216–224) with the new block that checks `cd == 0` for the instant-spawn path, and uses `self._spawn_timer:reset(cd)` on the normal path, reading `spawn_cooldown(self.game_state)`

---

## Group C — Buy scene UI (must follow Group A)

- [x] **Require cooldown tiers in buy scene** — `lua/game/scenes/buy_scene.lua`: at the top of the file alongside `SPEED_TIERS` and `GROWTH_TIERS` requires (after line 9), add `local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")`

- [x] **Add catalogue entry** — `lua/game/scenes/buy_scene.lua`: after the `"growth_boost"` `CATALOGUE[#CATALOGUE + 1]` block (after line 59), append a new entry with `label = "Rush Hour"`, `description = "More customers, faster."`, `kind = "customer_cooldown"` (no `image` field)

- [x] **Add `_confirm` branch for customer_cooldown (must follow COOLDOWN_TIERS require and cooldown_level tasks)** — `lua/game/scenes/buy_scene.lua`: in `BuyScene:_confirm`, after the `growth_boost` `if` block (after line 136), add a new `if ent.kind == "customer_cooldown" then` block that guards on `gs.cooldown_level >= #COOLDOWN_TIERS`, checks `gs.currency < tier.cost`, deducts currency, increments `gs.cooldown_level`, calls `Sound.play("shop_buy")`, and returns

- [x] **Add `draw` cost/desc/can_buy branch for customer_cooldown (must follow COOLDOWN_TIERS require and cooldown_level tasks)** — `lua/game/scenes/buy_scene.lua`: in `BuyScene:draw`, inside the `display_cost / display_desc / can_buy` resolution block, add an `elseif ent.kind == "customer_cooldown" then` branch (after the `growth_boost` elseif, before the final `else`) that sets `display_cost = "---"` / `display_desc = "Max cooldown reached."` / `can_buy = false` when maxed, or builds `display_cost`, `display_desc` (base description plus `"\n"` plus cooldown string: `"instant"` or `"Xs between customers"`), and `can_buy` from the next tier

- [x] **Add icon draw branch for customer_cooldown (must follow ads asset task)** — `lua/game/scenes/buy_scene.lua`: in `BuyScene:draw`, inside the item preview `if/elseif` chain (after the `speed_boost` special case at line 236), add an `elseif ent.kind == "customer_cooldown" then` branch that computes `icon_lvl = math.min(gs.cooldown_level + 1, #A.ads)`, retrieves `A.ads[icon_lvl]`, and draws it at `CENTER_X - PREVIEW_SIZE / 2, y` scaled to `PREVIEW_SIZE`
