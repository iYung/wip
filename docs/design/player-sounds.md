# Player Sounds

## Goal

Add sound effects for every player-triggered action. Background music is out of scope. Sounds play at fixed volume (no settings control). The system must be silent in headless/test mode.

---

## Affected files

**New:**
- `lua/game/sound.lua` — load and play named sounds
- `assets/sounds/` — one placeholder `.ogg` per sound event (16 files)

**Modified:**
- `lua/headless/stubs.lua` — add `love.audio` stub so Sound module no-ops cleanly
- `lua/game/items/plant.lua` — emit `plant_ready`; return bool from `:water()` for caller-side sound
- `lua/game/items/watering_can.lua` — play `water_plant` when `:water()` returns true
- `lua/game/items/grafter.lua` — play `clone_success` or `clone_fail`
- `lua/game/scenes/store_scene.lua` — play pick_up, put_down, sell_plant, dismiss_customer, dialogue_advance, dialogue_skip, discard_plant, open_shop
- `lua/game/scenes/buy_scene.lua` — play shop_navigate, shop_buy, shop_close
- `lua/game/scenes/start_scene.lua` — play menu_navigate, menu_confirm

---

## What changes

### `lua/game/sound.lua` (new)

A thin singleton module that mirrors how `lua/game/assets.lua` works.

```lua
local Sound = {}
local _src = {}

function Sound.load()
    if not love.audio then return end
    local names = { ... }  -- list of all event names
    for _, name in ipairs(names) do
        local path = "assets/sounds/" .. name .. ".ogg"
        if love.filesystem.getInfo(path) then
            _src[name] = love.audio.newSource(path, "static")
        end
    end
end

function Sound.play(name)
    if not love.audio then return end
    local s = _src[name]
    if s then love.audio.play(s:clone()) end
end

return Sound
```

Each call to `Sound.play` clones the source so overlapping playback works (e.g. rapid watering).

`Sound.load()` is called once from `main.lua` inside `love.load`.

### `assets/sounds/` (new)

16 placeholder `.ogg` files — one per event. These are valid but silent/minimal files so `love.audio.newSource` succeeds. Replace with real audio files later without any code changes.

| Event name | When it plays |
|---|---|
| `pick_up` | Player picks up a carriable item from a slot |
| `put_down` | Player places held item into an empty slot |
| `water_plant` | Watering can successfully advances a plant's stage |
| `plant_ready` | Plant growth timer completes; bubble appears |
| `clone_success` | Grafter successfully clones a stage-3 plant |
| `clone_fail` | Grafter used but no empty slot available |
| `sell_plant` | Player successfully sells plant to customer |
| `dismiss_customer` | Player dismisses a waiting customer |
| `dialogue_skip` | Player skips typewriter reveal mid-message |
| `dialogue_advance` | Player advances to the next dialogue line |
| `discard_plant` | Player discards held item into garbage bin |
| `open_shop` | Player opens the PC store / buy scene |
| `shop_navigate` | Player cycles items left or right in the buy scene |
| `shop_buy` | Player successfully purchases an item |
| `shop_close` | Player closes the buy scene (E key) |
| `menu_navigate` | Player moves cursor in the start screen menu |
| `menu_confirm` | Player confirms a selection in the start screen menu |

### `lua/headless/stubs.lua`

Add a `love.audio` stub with no-op methods so `Sound.load()` / `Sound.play()` can check `love.audio` and safely no-op without nil-indexing:

```lua
love.audio = {
    newSource = function() return { clone = function(s) return s end } end,
    play      = function() end,
}
```

> Without this, `love.audio` is `nil` in headless, and `Sound` already guards on `if not love.audio`. The stub is added for defensive completeness — it means Sound can skip the nil check if desired, and any future code that references `love.audio` directly won't crash tests.

### `lua/game/items/plant.lua`

Two changes:

1. `Plant:water()` returns `true` on success, `false` otherwise (was void). Callers can react to the result.
2. `Plant:update()` calls `Sound.play("plant_ready")` when the cooldown fires and the bubble appears.

### `lua/game/items/watering_can.lua`

`WateringCan:interact()` calls `Sound.play("water_plant")` when `slot.item:water()` returns `true`.

### `lua/game/items/grafter.lua`

`Grafter:interact()` calls `Sound.play("clone_success")` when a clone is placed, or `Sound.play("clone_fail")` when no empty slot is found.

### `lua/game/scenes/store_scene.lua`

`_handle_pick_up_down`:
- After `slot.item = player.held_item; player.held_item = nil` → `Sound.play("put_down")`
- After `player.held_item = slot.item; slot.item = nil` → `Sound.play("pick_up")`
- After `self._customer:dismiss()` → `Sound.play("dismiss_customer")`

`_handle_interact`:
- After `player.held_item = nil` (garbage bin discard) → `Sound.play("discard_plant")`
- After `self._customer:serve()` (successful sale) → `Sound.play("sell_plant")`
- After `self._customer:skip_reveal()` → `Sound.play("dialogue_skip")`
- After `self._customer:advance()` → `Sound.play("dialogue_advance")`
- When `item.buy_scene_factory` triggers a scene switch → `Sound.play("open_shop")`

### `lua/game/scenes/buy_scene.lua`

`update`:
- After left/right navigation changes `self.selected` → `Sound.play("shop_navigate")`
- After E key triggers `scene_manager:switch` back to store → `Sound.play("shop_close")`

`_confirm`:
- After a successful purchase (any kind) → `Sound.play("shop_buy")`

### `lua/game/scenes/start_scene.lua`

`update`:
- After up/down changes `self.selected` → `Sound.play("menu_navigate")`

`_confirm`:
- At the top (before any branch) → `Sound.play("menu_confirm")`

---

## What stays the same

- No settings changes: SFX volume is not configurable.
- `lua/game/assets.lua` is untouched; Sound is a parallel, independent module.
- Headless tests continue to run silently with no real audio calls.
- No background music infrastructure is added.
- The `Sound` module is passive — it has no update loop and no state beyond the loaded sources.

---

## Open questions

None — all answered before writing this doc.
