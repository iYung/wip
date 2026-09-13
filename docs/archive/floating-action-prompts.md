# Floating Action Prompts Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — Implement `_draw_floating_prompts()` and wire it into `draw()`
- [x] Task B — `tests/test_hud_labels.lua` — Add tests covering floating prompt scenarios

---

## Task A detail

Add two local helpers near the top of `store_scene.lua` (after requires, before StoreScene):

```lua
local function _world_to_screen(camera, wx, wy)
    local z = camera.zoom
    return (wx - camera.x) * z + camera._w / 2,
           (wy - camera.y) * z + camera._h / 2
end

local function _draw_chip(x, y, key_text, action_text, font)
    -- x,y is the center-bottom anchor of the chip
    local key_w    = font:getWidth("[" .. key_text .. "]")
    local act_w    = font:getWidth(" " .. action_text)
    local total_w  = key_w + act_w + 12   -- 6px pad each side
    local box_h    = font:getHeight() + 8
    local bx       = math.floor(x - total_w / 2)
    local by       = math.floor(y - box_h)
    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.rectangle("fill", bx, by, total_w, box_h, 4, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("[" .. key_text .. "]", bx + 6, by + 4)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    love.graphics.print(" " .. action_text, bx + 6 + key_w, by + 4)
    love.graphics.setColor(1, 1, 1, 1)
end
```

Add a method `StoreScene:_draw_floating_prompts()`:

```lua
function StoreScene:_draw_floating_prompts()
    local gs     = self.game_state
    local player = gs.player
    local font   = love.graphics.getFont()
    local hud    = self:_hud_labels()

    local chips = {}   -- { key, label }
    if hud.f  then
        local k = self.input:key_for("interact")     or "j"
        chips[#chips+1] = { key = k:upper(), label = _strip_label(hud.f) }
    end
    if hud.up then
        local action = hud.up
        local k
        if player.x < 0 then
            k = self.input:key_for("cancel")       or "l"
        else
            k = self.input:key_for("pick_up_down") or "k"
        end
        chips[#chips+1] = { key = k:upper(), label = _strip_label(action) }
    end
    if hud.down then
        local k = self.input:key_for("pick_up_down") or "k"
        chips[#chips+1] = { key = k:upper(), label = _strip_label(hud.down) }
    end

    if #chips == 0 then return end

    -- Anchor: above active slot (store zone) or above customer (cashier zone)
    local ax, ay
    if player.x >= 0 then
        local slot = player:active_slot(gs.store)
        if not slot then return end
        local wx = slot.x + slot.slot_width / 2
        local wy = slot.y - 16
        ax, ay = _world_to_screen(self.camera, wx, wy)
    else
        -- cashier zone: anchor above where the customer stands
        local wx = -require("lua/game/config").ZONE_WIDTH / 2
        local wy = 420   -- just above the customer y (500), in world coords
        ax, ay = _world_to_screen(self.camera, wx, wy)
    end

    local line_h = font:getHeight() + 10
    for i, chip in ipairs(chips) do
        local cy = ay - (i - 1) * line_h
        _draw_chip(ax, cy, chip.key, chip.label, font)
    end
end
```

Also add a local helper `_strip_label(entry)` that converts the mixed string/table hud entries to a plain string:

```lua
local function _strip_label(entry)
    if type(entry) == "table" then return entry.text:gsub("^: ", "") end
    return entry:gsub("^%u+: ", "")   -- strip "K: " prefix from text-only entries
end
```

Call it in `StoreScene:draw()` after the existing label text loop and before the final `setColor(1,1,1,1)`:

```lua
self:_draw_floating_prompts()
```

---

## Task B detail

In `tests/test_hud_labels.lua`, read the existing test patterns to understand setup, then add cases:

1. **Empty-handed near carriable item** — `hud.up` contains PICK UP, no `hud.f` action (no interact targets)
2. **Holding watering can near a ready plant** — `hud.f` contains WATER, `hud.up` absent or PUT DOWN in empty slot
3. **In cashier zone with customer arrived** — `hud.f` shows NEXT/SKIP/SELL, `hud.up` shows DISMISS

These mirror the scenarios in the existing tests but confirm the floating prompt data is populated correctly (the prompts themselves use the same `_hud_labels()` output, so these tests transitively validate what the floating prompts would show).
