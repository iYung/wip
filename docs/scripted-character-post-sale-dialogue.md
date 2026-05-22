# Scripted Character: Post-Sale Dialogue

## Current Flow

```
walk_in → waiting → [player clicks through messages] → [last message + correct plant]
→ serve() → heart_bubble shows → walk_out → idle
```

The sale is the final interaction. Once the player hands over the plant, the customer immediately shows a heart and walks away.

---

## Goal

Add an optional set of lines a scripted character can say **after** receiving the plant — a reaction, a parting thought, or a character beat — before they walk out.

```
walk_in → waiting → [player clicks through messages] → [sale]
→ after_messages → [player clicks through] → heart_bubble → walk_out → idle
```

---

## Data Changes

### `customer_scripts.lua` — add `after_messages` field

Each script entry can optionally include an `after_messages` table. If absent, the character behaves exactly as today (immediate heart + walk-out on sale).

```lua
{
    id      = "old_pete",
    chapter = 1,
    ...
    messages = {
        "Haven't seen you before.",
        "You grow plants here, yeah?",
        "I'll take a cactus if you've got one.",
    },
    after_messages = {
        "..Yeah. This'll do nicely.",
    },
},
```

---

## Customer State Machine

Add a new state: **`"talking_after"`**

| State | Description |
|---|---|
| `idle` | Off-screen, invisible |
| `walking_in` | Moving to target_x |
| `waiting` | At counter, pre-sale dialogue |
| `talking_after` | At counter, post-sale dialogue (new) |
| `walking_out` | Moving to exit_x |

### New fields on `Customer`

```lua
self.after_messages   = {}    -- loaded from cfg.after_messages
self.after_msg_index  = 1
self.done_after       = false -- true when after_messages exhausted
```

### `Customer:show(cfg)` change

Load `after_messages` from cfg alongside `messages`:

```lua
self.after_messages  = cfg.after_messages or {}
self.after_msg_index = 1
self.done_after      = #self.after_messages == 0
```

### `Customer:serve()` change

Instead of immediately walking out, enter `talking_after` if there are lines to show:

```lua
function Customer:serve()
    self.bubble.visible = false
    if not self.done_after then
        self.state = "talking_after"
        -- reset typewriter for first after_message
        self._full_text   = self.name .. ": " .. self.after_messages[1]
        self.reveal_index = 0
        self.reveal_t     = 0
        self.bubble.visible = true
    else
        self.state = "walking_out"
        self.heart_bubble.visible = true
    end
end
```

### New method: `Customer:advance_after()`

Mirrors `advance()` but works on `after_messages`. Called by `store_scene` when player clicks interact during `talking_after`.

```lua
function Customer:advance_after()
    if self.done_after then return end
    if self.after_msg_index < #self.after_messages then
        self.after_msg_index = self.after_msg_index + 1
        self._full_text   = self.name .. ": " .. self.after_messages[self.after_msg_index]
        self.reveal_index = 0
        self.reveal_t     = 0
    else
        self.done_after = true
        self.state = "walking_out"
        self.bubble.visible = false
        self.heart_bubble.visible = true
    end
end
```

### `Customer:update()` change

Typewriter reveal should run during `talking_after` the same way it does during `waiting`:

```lua
if self.bubble.visible and (not self.done_talking or self.state == "talking_after") then
    -- existing typewriter logic
end
```

---

## `store_scene.lua` Changes

### `_handle_interact()` — cashier zone block

Currently the block only runs when `self._customer:arrived()` (i.e. state == `"waiting"`). Extend the condition to also handle `talking_after`.

```lua
if player.x < 0 and (self._customer:arrived() or self._customer.state == "talking_after") then
```

Inside, branch on state:

```lua
if self._customer.state == "talking_after" then
    if not self._customer:line_complete() then
        self._customer:skip_reveal()
    else
        self._customer:advance_after()
    end
    return
end
```

The existing sale-or-advance block runs unchanged when `arrived()` (state == `"waiting"`).

### `_handle_pick_up_down()` — dismiss during `talking_after`

Dismissing mid-after-dialogue: the sale already happened, so no cooldown needed. Just send them walking out immediately.

```lua
if self._customer:arrived() or self._customer.state == "talking_after" then
    self._customer:dismiss()
    -- only set cooldown if the sale hadn't happened yet
    if self._customer:arrived() and self._active_script_key then
        self._script_cooldowns[self._active_script_key] = DISMISS_COOLDOWN_SALES
        self._active_script_key = nil
    end
end
```

---

## HUD Labels

`_hud_labels()` currently shows a prompt near the cashier zone. During `talking_after` the prompt should remain (player still clicks to advance), but the SELL label should not show — the sale is done. No new logic needed if the prompt is generic ("INTERACT"), but worth verifying what currently renders.

---

## Backwards Compatibility

- `after_messages` is optional. Scripts without it behave exactly as today.
- Random (non-scripted) customers have no `after_messages` and are unaffected.
- No changes to `seen_scripts` timing — it is still written at the moment of sale, not after after_messages.

---

## Steps

1. **`customer.lua`** — add `after_messages`, `after_msg_index`, `done_after` fields; update `show()`, `serve()`, `update()`; add `advance_after()`
2. **`store_scene.lua`** — extend cashier-zone condition in `_handle_interact()`; add `talking_after` branch; update `_handle_pick_up_down()` dismiss guard
3. **`customer_scripts.lua`** — add `after_messages` to any scripts that should have post-sale lines
4. **Tests** — add to `test_customer_scripts.lua`: after_messages plays after sale, advance_after walks out after last line, dismiss during talking_after skips to walk-out without setting cooldown
