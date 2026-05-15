# Growth Speed Upgrade Steps

Goal: a purchasable "Heat Lamps" upgrade in the PC Store shop. Three tiers, each permanently making all plants grow N% faster. Implemented by scaling the `dt` passed to the store — no changes to `Plant` or `Timer`.

---

## How it works

`Plant:update(dt)` feeds `dt` into its cooldown timer. `StoreScene:update` calls `gs.store:update(dt)`. To make timers tick faster, multiply `dt` by a growth multiplier before passing it to the store. A multiplier of `1.5` makes every timer count 50% faster (1.5× real time), so a 10s cooldown finishes in ~6.7s.

`GameState` holds `growth_level` (tier 0–3) and `growth_mult` (float derived from the current tier). BuyScene reads these to display the next tier and apply the purchase.

---

## Tiers

| Tier | Cost | Multiplier | Effect |
|------|------|-----------|--------|
| 0 (base) | — | 1.0 | no change |
| 1 | $20 | 1.25 | 25% faster |
| 2 | $50 | 1.60 | 60% faster |
| 3 (max) | $100 | 2.00 | 2× as fast |

---

## Step 0 — Move speed_tiers out of config

`SPEED_TIERS` is game data, not engine config. Move it alongside the other data files before adding `GROWTH_TIERS`.

- [ ] Create `lua/game/data/speed_tiers.lua` returning the tiers table (copy the array from `config.lua`)
- [ ] Remove `SPEED_TIERS` from `lua/game/config.lua`
- [ ] In `buy_scene.lua`, replace `local SPEED_TIERS = config.SPEED_TIERS` with `local SPEED_TIERS = require("lua/game/data/speed_tiers")`

---

## Step 1 — Data

Create `lua/game/data/growth_tiers.lua`:

```lua
return {
    { cost = 20,  mult = 1.25 },
    { cost = 50,  mult = 1.60 },
    { cost = 100, mult = 2.00 },
}
```

---

## Step 2 — GameState

Add two fields to `GameState.new()` in `lua/game/game_state.lua`:

```lua
self.growth_level = 0
self.growth_mult  = 1.0
```

---

## Step 3 — StoreScene

In `StoreScene:update(dt)` in `lua/game/scenes/store_scene.lua`, replace:

```lua
gs.store:update(dt)
```

with:

```lua
gs.store:update(dt * gs.growth_mult)
```

That one change propagates the multiplier to every plant timer in the store, including plants placed after the upgrade is purchased.

Also pull in `GROWTH_TIERS` from config at the top of the file:

```lua
local GROWTH_TIERS = config.GROWTH_TIERS
```

(Or pull it in `buy_scene.lua` only — it's only needed there for the purchase logic. `store_scene.lua` only reads `gs.growth_mult`, which is already set on GameState.)

---

## Step 4 — BuyScene: require and catalogue entry

At the top of `lua/game/scenes/buy_scene.lua`, add alongside `SPEED_TIERS`:

```lua
local GROWTH_TIERS = require("lua/game/data/growth_tiers")
```

Add one entry to `CATALOGUE` after the Speed Boost entry:

```lua
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Heat Lamps",
    description = "Warm your plants.\nThey grow faster!",
    kind        = "growth_boost",
    image       = A.heat_lamps,   -- add asset or use nil to fall back to grey rect
}
```

If no `heat_lamps` art exists yet, omit the `image` field — the draw code already falls back to a grey rectangle.

---

## Step 5 — BuyScene: draw

In `BuyScene:draw()`, the `speed_boost` block already shows dynamic cost/desc. Add a parallel block for `growth_boost` right after it:

```lua
elseif ent.kind == "growth_boost" then
    if gs.growth_level >= #GROWTH_TIERS then
        display_cost = "---"
        display_desc = "Max growth reached."
        can_buy      = false
    else
        local tier   = GROWTH_TIERS[gs.growth_level + 1]
        display_cost = "$" .. tier.cost
        display_desc = ent.description .. "\n" .. math.floor(tier.mult * 100 - 100) .. "% faster"
        can_buy      = currency >= tier.cost
    end
```

The description already lives in the catalogue entry; the second line appends the numeric benefit so the player sees exactly what they're buying.

---

## Step 6 — BuyScene: confirm

In `BuyScene:_confirm()`, add a branch for `growth_boost` right after the `speed_boost` branch:

```lua
if ent.kind == "growth_boost" then
    if gs.growth_level >= #GROWTH_TIERS then return end
    local tier = GROWTH_TIERS[gs.growth_level + 1]
    if gs.currency < tier.cost then return end
    gs.currency     = gs.currency - tier.cost
    gs.growth_level = gs.growth_level + 1
    gs.growth_mult  = tier.mult
    return   -- stay in shop
end
```

No plant iteration needed — `gs.growth_mult` is read each frame in `StoreScene:update`, so all existing and future plants benefit immediately.

---

## Step 7 — End-to-end test

- [ ] Open shop — Heat Lamps entry appears in carousel
- [ ] With < $20 — entry is dimmed, F does nothing
- [ ] Buy tier 1 ($20) — `growth_level = 1`, `growth_mult = 1.25`; plant timers visibly tick faster
- [ ] Re-open shop — cost now shows $50, description shows 60% faster
- [ ] Buy tier 2, then tier 3 — each step faster
- [ ] At max — entry shows "Max growth reached.", cost shows "---", F does nothing
- [ ] Plants placed after upgrade inherit multiplier immediately (no per-plant state needed)
- [ ] Speed upgrade still works independently
- [ ] Multiplier applies to all 6 plant types and both stage timers
