# Design: Customer Cooldown Upgrade

## Goal

Add a purchasable upgrade in the PC store (`buy_scene.lua`) that lowers the fixed wait time between customer spawns. The current code draws a random interval (`math.random(3, 6)`) on each spawn cycle; this feature replaces that with a fixed, upgrade-controlled interval. Four tiers exist:

| Level | Cooldown |
|-------|----------|
| 0 (default, no upgrade) | 4 seconds |
| 1 | 3 seconds |
| 2 | 2 seconds |
| 3 | 0 seconds (back-to-back; next customer spawns immediately after previous one exits) |

---

## Affected Files

- `lua/game/data/cooldown_tiers.lua` — **new file**: tier table (cost + cooldown per level), mirroring `speed_tiers.lua` / `growth_tiers.lua`
- `lua/game/assets.lua` — add `A.ads` table: `A.ads[1..3]` loaded via `try_img("assets/ads_N.png")`
- `lua/game/game_state.lua` — add `cooldown_level` field (default `0`)
- `lua/game/scenes/store_scene.lua` — replace both `math.random(3, 6)` spawn-timer usages with a helper that reads `gs.cooldown_level`; handle the 0-second (instant) tier
- `lua/game/scenes/buy_scene.lua` — add a `"customer_cooldown"` catalogue entry; add `_confirm` branch; add `draw` branch (tier icon from `A.ads[gs.cooldown_level + 1]`, cost, description, max-reached text)

---

## What Changes

### 1. New data file: `lua/game/data/cooldown_tiers.lua`

Create a table indexed 1–3 (levels 1, 2, 3) following the same structure as `speed_tiers.lua`. Level 0 is the default and lives in `game_state`, not in this table.

```lua
return {
    { cost = 10,  cooldown = 3 },  -- level 1
    { cost = 25,  cooldown = 2 },  -- level 2
    { cost = 50,  cooldown = 0 },  -- level 3 (instant)
}
```

### 1b. `lua/game/assets.lua` — add ads icon table

After the `heat_lamps` block:

```lua
A.ads = {}
for lvl = 1, 3 do
    A.ads[lvl] = try_img("assets/ads_" .. lvl .. ".png")
end
```

### 2. `lua/game/game_state.lua`

Add one field to `GameState.new()`:

```lua
self.cooldown_level = 0
```

This mirrors `speed_level` and `growth_level` already present in the same block.

### 3. `lua/game/scenes/store_scene.lua`

**3a. Require the new tier table** at the top of the file (alongside existing requires):

```lua
local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")
```

**3b. Add a helper** that converts the current `cooldown_level` to a spawn interval:

```lua
local function spawn_cooldown(gs)
    if gs.cooldown_level == 0 then return 4 end
    return COOLDOWN_TIERS[gs.cooldown_level].cooldown
end
```

**3c. Line ~82 — initial timer setup in `_setup_store`:**

Replace:
```lua
self._spawn_timer = Timer.new(math.random(3, 6))
```
With:
```lua
self._spawn_timer = Timer.new(spawn_cooldown(gs))
```

**3d. Lines ~217–222 — timer reset in `update`:**

The current block is:
```lua
if not self._customer:active() then
    if self._spawn_timer:update(dt) then
        local cfg = self:_next_customer_cfg()
        if cfg then
            self._customer:show(cfg)
        end
        self._spawn_timer:reset(math.random(3, 6))
    end
end
```

Replace with:
```lua
if not self._customer:active() then
    local cd = spawn_cooldown(self.game_state)
    if cd == 0 then
        -- instant tier: spawn immediately whenever no customer is active
        local cfg = self:_next_customer_cfg()
        if cfg then
            self._customer:show(cfg)
        end
    elseif self._spawn_timer:update(dt) then
        local cfg = self:_next_customer_cfg()
        if cfg then
            self._customer:show(cfg)
        end
        self._spawn_timer:reset(cd)
    end
end
```

Note: when the player upgrades to level 3 mid-session the existing `_spawn_timer` will eventually fire (or the customer walk-out will clear `active()`), and on the very next frame the instant path takes over. No extra reset logic is needed.

### 4. `lua/game/scenes/buy_scene.lua`

**4a. Require the tier table** at the top (alongside `SPEED_TIERS` / `GROWTH_TIERS`):

```lua
local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")
```

**4b. Add a catalogue entry** after the existing `"growth_boost"` entry and before the closing `}`:

```lua
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Rush Hour",
    description = "More customers, faster.",
    kind        = "customer_cooldown",
}
```

No `image` field — the `draw` branch handles tier icons dynamically (see 4d).

The description is a 1-line base (per the PC Store description 2-line rule; tier detail is appended dynamically in `draw`, same as growth_boost).

**4c. `_confirm` — add a branch** parallel to the `speed_boost` / `growth_boost` blocks:

```lua
if ent.kind == "customer_cooldown" then
    if gs.cooldown_level >= #COOLDOWN_TIERS then return end
    local tier = COOLDOWN_TIERS[gs.cooldown_level + 1]
    if gs.currency < tier.cost then return end
    gs.currency       = gs.currency - tier.cost
    gs.cooldown_level = gs.cooldown_level + 1
    Sound.play("shop_buy")
    return
end
```

**4d. `draw` — add display logic** in the `display_cost / display_desc / can_buy` resolution block, parallel to `growth_boost`. Also add a special icon draw case that renders `A.ads[gs.cooldown_level + 1]` (next tier icon) or `A.ads[3]` when maxed:

```lua
elseif ent.kind == "customer_cooldown" then
    if gs.cooldown_level >= #COOLDOWN_TIERS then
        display_cost = "---"
        display_desc = "Max cooldown reached."
        can_buy      = false
    else
        local tier   = COOLDOWN_TIERS[gs.cooldown_level + 1]
        display_cost = "$" .. tier.cost
        local cd_str = tier.cooldown == 0 and "instant" or (tier.cooldown .. "s between customers")
        display_desc = ent.description .. "\n" .. cd_str
        can_buy      = currency >= tier.cost
    end
```

Icon draw (in the image preview section, parallel to the `speed_boost` special case):

```lua
elseif ent.kind == "customer_cooldown" then
    local icon_lvl = math.min(gs.cooldown_level + 1, #A.ads)
    local icon = A.ads[icon_lvl]
    if icon then
        love.graphics.draw(icon,
            PREVIEW_X, PREVIEW_Y,
            0,
            PREVIEW_SIZE / icon:getWidth(),
            PREVIEW_SIZE / icon:getHeight())
    end
```

---

## What Stays the Same

- All existing upgrade tiers (`speed_tiers`, `growth_tiers`) and their purchase logic are untouched.
- `Customer`, `Timer`, and all other files are not modified.
- The scripted-customer selection logic (`_next_customer_cfg`) and dismiss cooldown logic are untouched.
- The random customer config generation (random colors, random plant type from unlocked set) is untouched.
- Save/persist: the game has no save system yet — `game_state` is constructed fresh on launch, so `cooldown_level = 0` persists only for the session, exactly like `speed_level` and `growth_level`.

---

## Resolved Decisions

- **Icon assets**: `assets/ads_1.png`, `assets/ads_2.png`, `assets/ads_3.png` already exist (created by user). Loaded as `A.ads[1..3]` via `try_img`.
- **Costs**: $10 / $25 / $50 confirmed.
- **Instant-spawn feel**: Truly instant (0s, same frame). Customers still walk on/off screen so this is acceptable.
- **Timer reuse on upgrade**: New cooldown takes effect on next timer cycle (intentional, same as other upgrades).

## Open Questions

None — all decisions resolved.
