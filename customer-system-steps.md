# Customer System Steps

Goal: scripted customers with unique appearance and dialog that trigger when a plant type has hit stage 3 a certain number of times; random customers only request plant types the player has already purchased.

---

## Design

```
gs.unlocked_plants      -- set { [plant_type] = true } — updated on purchase
gs.stage3_counts        -- table { [plant_type] = n } — incremented each time that type hits stage 3
gs.seen_scripts         -- set { [script_id] = true } — prevents a scripted customer firing twice
```

**Scripted customers** — an ordered array in `customer_scripts.lua`. Each entry has an `id` and a `trigger = { plant_type, count }` meaning "plant_type has hit stage 3 at least `count` times." At spawn time, scan the array for the first unseen entry whose trigger is satisfied; if found, spawn that customer.

**Random customers** — pick uniformly from `gs.unlocked_plants`. If the set is empty, skip the spawn (timer still resets).

**Dialog** — customers have an ordered `messages` array and a `msg_index`. F advances through messages. On the last message, F triggers the sale if the player is holding the correct plant; otherwise does nothing. Random customers get a single-message array auto-built from the plant name.

---

## Step 1 — GameState

- [ ] Add `unlocked_plants = { [1] = true }` to `GameState.new()` — Fern is unlocked from the start
- [ ] Add `stage3_counts  = {}` to `GameState.new()`
- [ ] Add `seen_scripts   = {}` to `GameState.new()`

---

## Step 2 — Track Plant Purchases (BuyScene)

- [ ] In `BuyScene:_confirm()`, after a successful `kind == "plant"` purchase, set `gs.unlocked_plants[ent.plant_type] = true`

---

## Step 3 — Track Stage-3 Maturities (StoreScene)

Detect when a watering action advances a plant to stage 3.

- [ ] In `StoreScene:_handle_interact()`, in the watering-can branch, snapshot `slot.item.stage` before calling `item:interact()`, then check if it became 3 afterward:
  ```lua
  local prev_stage = slot.item and slot.item.stage
  item:interact(player, store, self.scene_manager)
  if slot.item and slot.item.stage == 3 and prev_stage == 2 then
      local pt = slot.item.plant_type
      self.game_state.stage3_counts[pt] = (self.game_state.stage3_counts[pt] or 0) + 1
  end
  ```

---

## Step 4 — Customer Data (`lua/game/data/customer_scripts.lua`)

An ordered array. `trigger.count` is the minimum number of times `trigger.plant_type` must have hit stage 3 for this entry to be eligible. Scripts are checked in order; the first unseen eligible entry is chosen.

```lua
return {
    {
        id         = "old_pete",
        trigger    = { plant_type = 1, count = 2 },  -- grew Fern to stage 3 twice
        name       = "Old Pete",
        body_color = {0.25, 0.45, 0.80, 1},
        plant_type = 2,  -- wants Cactus
        messages   = {
            "Haven't seen you before.",
            "You grow plants here, yeah?",
            "I'll take a cactus if you've got one.",
        },
    },
    {
        id         = "mayor_bloom",
        trigger    = { plant_type = 3, count = 1 },  -- grew Rose to stage 3 once
        name       = "Mayor Bloom",
        body_color = {0.75, 0.25, 0.40, 1},
        plant_type = 3,  -- wants Rose
        messages   = {
            "The town council is watching this place.",
            "Only the finest rose will do.",
        },
    },
    {
        id         = "the_collector",
        trigger    = { plant_type = 6, count = 1 },  -- grew Golden Lotus to stage 3 once
        name       = "The Collector",
        body_color = {0.85, 0.75, 0.10, 1},
        plant_type = 6,  -- wants Golden Lotus
        messages   = {
            "I've come a long way.",
            "They say you can grow the Golden Lotus.",
            "I'll pay handsomely. Do we have a deal?",
        },
    },
}
```

---

## Step 5 — Customer Class

- [ ] Add properties: `name`, `messages`, `msg_index`
- [ ] Change `Customer:show(cfg)` — `cfg` is a table:
  ```lua
  {
      plant_type = 1,
      messages   = { "Fern" },
      name       = "Customer",     -- default
      body_color = nil,            -- falls back to orange {0.85, 0.55, 0.30, 1}
  }
  ```
- [ ] In `show()`:
  - Copy all cfg fields onto self; set `self.msg_index = 1`
  - Apply `cfg.body_color` to `self.sprite.color` if provided, else reset to default orange
- [ ] Add `Customer:advance()` — increments `msg_index` if not on the last message
- [ ] Add `Customer:on_last_message()` — returns `msg_index >= #self.messages`
- [ ] In `draw_bubble()`, show current message:
  ```lua
  local line = self.messages[self.msg_index]
  love.graphics.print(self.name .. ": " .. line, ...)
  ```

---

## Step 6 — Interact Logic (StoreScene)

Replace the single cashier F check with a two-case branch:

```
if player.x < 0 AND customer:arrived():
    if customer:on_last_message() AND holding correct plant:
        → sale (pay 2× value, clear held_item, customer:serve())
    else:
        → customer:advance()
    return
```

- [ ] Update `StoreScene:_handle_interact()` with the above
- [ ] Update `StoreScene:_hud_labels()`:
  - Last message + correct plant held → `"F: SELL TO CUSTOMER ($X)"`
  - Otherwise (still in dialog, or wrong/no plant) → `"F: NEXT"`

---

## Step 7 — Spawn Logic (StoreScene)

- [ ] Require `CUSTOMER_SCRIPTS` from `lua/game/data/customer_scripts`
- [ ] Add `StoreScene:_next_customer_cfg()`:
  ```
  gs = self.game_state

  -- check scripted queue
  for each script in CUSTOMER_SCRIPTS:
      if not gs.seen_scripts[script.id]:
          t = script.trigger
          if (gs.stage3_counts[t.plant_type] or 0) >= t.count:
              gs.seen_scripts[script.id] = true
              return script

  -- fall back to random
  collect keys from gs.unlocked_plants into an array
  if empty → return nil
  pick random plant_type N
  return { plant_type = N, messages = { PLANT_DATA[N].name } }
  ```
- [ ] In the spawn block: if cfg is nil, reset timer and skip; otherwise `_customer:show(cfg)`

---

## Step 8 — End-to-End Test

- [ ] From the start, random customers spawn and ask for Fern (unlocked by default)
- [ ] Buy Cactus → random customers now ask for Fern or Cactus; F on last message sells, F before last advances
- [ ] Grow Fern to stage 3 twice → Old Pete becomes eligible; next spawn is Old Pete (blue body, 3-message dialog, wants Cactus)
- [ ] Old Pete spawns regardless of whether Cactus is in `unlocked_plants`
- [ ] Work through Old Pete's dialog; F on messages 1–2 advances; F on message 3 with Cactus in hand → sale
- [ ] F on message 3 without Cactus → nothing (no accidental advance or sale)
- [ ] Grow Rose to stage 3 → Mayor Bloom becomes eligible on next scripted spawn
- [ ] Grow Golden Lotus to stage 3 → The Collector becomes eligible
- [ ] After all scripts seen, spawn falls back to random unlocked plants indefinitely

---

## Open Questions

- Should the wrong-plant case on the last message show `"F: NEED <plant>"` instead of nothing?
- Should the bubble auto-size width to fit the longest message, or wrap at a fixed width?
- Should scripted customers still pay 2× value, or have a custom multiplier per script entry?
