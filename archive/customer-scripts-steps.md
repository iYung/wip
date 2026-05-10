# Customer Scripts — Return Customers & Questlines

Goal: make the world feel lived-in by having named regulars return over time, and let some of them carry a short questline across multiple visits.

Current system recap:
- `CUSTOMER_SCRIPTS` is a flat list of one-shot scripts, each with a `trigger` (plant_type + count) and an `id` recorded in `gs.seen_scripts` once shown.
- After all scripts are exhausted, random anonymous customers spawn.
- `game_state` tracks `seen_scripts`, `stage3_counts`, `unlocked_plants`, `currency`.

---

## Step 1 — Add `chapter` field to scripts

- [ ] Extend script entries with `id`, `chapter`, and optional `accessory` fields
- [ ] Update existing 3 scripts (`old_pete`, `mayor_bloom`, `the_collector`) to the new format

Extend the script format with just one new field:

| Field | Meaning |
|---|---|
| `id` | unique string, same across all chapters |
| `chapter` | integer (1, 2, 3…); chapter 1 is the first visit |
| `trigger` | plant milestone that must be met for this chapter to appear |
| `name`, `body_color`, `plant_type`, `messages` | same as before |

Example shape:
```lua
{
    id       = "old_pete",
    chapter  = 1,
    trigger  = { plant_type = 1, count = 1 },
    name     = "Old Pete",
    body_color = {0.25, 0.45, 0.80, 1},
    plant_type = 2,
    messages = { "Haven't seen you before.", "You grow plants here?", "I'll take a cactus." },
},
{
    id       = "old_pete",
    chapter  = 2,
    trigger  = { plant_type = 2, count = 3 },
    name     = "Old Pete",
    body_color = {0.25, 0.45, 0.80, 1},
    plant_type = 2,
    messages = { "Back again.", "That last cactus is doing great.", "Got another?" },
},
```

Scripts with the same `id` are chapters of the same character. No visit counter needed — chapter order is enforced by requiring all prior chapters seen.

---

## Step 2 — Rewrite `_next_customer_cfg()` selection logic

- [ ] Update `seen_scripts` key format to `id..":"..chapter`
- [ ] Add prior-chapter check before qualifying a script
- [ ] Verify fallback to anonymous customer still works

New priority order:
1. Find all scripts where:
   - Trigger is met (`gs.stage3_counts[t.plant_type] >= t.count`)
   - This chapter hasn't been seen (`gs.seen_scripts[id..":"..chapter]` is nil)
   - All prior chapters for the same `id` have been seen
2. Among those, pick randomly (multiple characters can qualify at once).
3. Fall back to anonymous random customer as before.

Mark seen as `gs.seen_scripts[id .. ":" .. chapter] = true` instead of just `id`.

---

## Step 3 — Accessories

- [ ] Add `A.load_accessory(name)` to `assets.lua`
- [ ] Add `accessory_sprite` field to `Customer.new()`
- [ ] Set accessory in `Customer:show(cfg)`
- [ ] Sync position and flip in `Customer:update()`
- [ ] Draw accessory in `Customer:draw()`

Accessories are optional sprites drawn over the top half of a named customer. They flip with the character and are invisible on anonymous customers.

### Script format

Add an optional `accessory` field (string key) to any script entry:

```lua
{
    id         = "old_pete",
    chapter    = 1,
    accessory  = "flat_cap",   -- nil = no accessory
    ...
}
```

### Asset loading in `assets.lua`

Accessory PNGs live in `assets/accessories/<name>.png`. Load lazily using `love.filesystem.getInfo` so a missing file doesn't crash:

```lua
A.accessories = {}
function A.load_accessory(name)
    if A.accessories[name] ~= nil then return A.accessories[name] end
    local path = "assets/accessories/" .. name .. ".png"
    if love.filesystem.getInfo(path) then
        A.accessories[name] = love.graphics.newImage(path)
    else
        A.accessories[name] = false   -- cache the miss
    end
    return A.accessories[name]
end
```

### Customer changes (`customer.lua`)

Add `self.accessory_sprite = nil` in `Customer.new()`.

In `Customer:show(cfg)`, set it if an accessory is specified:

```lua
if cfg.accessory then
    local img = A.load_accessory(cfg.accessory)
    if img then
        self.accessory_sprite = Sprite.new(0, 0, CW, CW)   -- square, top half height
        self.accessory_sprite.image = img
    else
        self.accessory_sprite = nil
    end
else
    self.accessory_sprite = nil
end
```

In `Customer:update()`, sync position and flip with the body sprite:

```lua
if self.accessory_sprite then
    self.accessory_sprite.x       = self.sprite.x
    self.accessory_sprite.y       = self.sprite.y
    self.accessory_sprite.scale_x = self.sprite.scale_x
    self.accessory_sprite.visible = self.sprite.visible
end
```

In `Customer:draw()`, draw the accessory after the body:

```lua
function Customer:draw()
    if self.state == "idle" then return end
    self.sprite:draw()
    if self.accessory_sprite then self.accessory_sprite:draw() end
end
```

### Sprite authoring notes (for later)

- Canvas size: 120×120 (CW × CW), transparent background
- Design for the character facing right — the flip handles left automatically
- Accessory sits at y=0 of the character (top of the 240px body), so draw it anchored to the top of the canvas

---

## Step 4 — Write the new customer scripts

- [ ] Old Pete — chapters 2 and 3
- [ ] Mayor Bloom — chapter 2
- [ ] The Collector — chapter 2
- [ ] Mira — new character, chapter 1
- [ ] Dottie — new character, chapters 1–3

### Old Pete (cactus regular, 3-chapter arc)

| Chapter | Trigger | Plant | Vibe |
|---|---|---|---|
| 1 | fern×1 | Cactus | first time in, gruff but curious |
| 2 | cactus×3 | Cactus | references the last one, warming up |
| 3 | cactus×6 | Cactus | calls you by name, small compliment |

### Mayor Bloom (rose questline, 2 chapters)

| Chapter | Trigger | Plant | Vibe |
|---|---|---|---|
| 1 | rose×1 | Rose | formal, the council watching |
| 2 | rose×4 | Rose | returns privately, less stiff, asks for another rose "for himself" |

### The Collector (golden lotus, 2 chapters)

| Chapter | Trigger | Plant | Vibe |
|---|---|---|---|
| 1 | golden lotus×1 | Golden Lotus | mysterious, distant |
| 2 | golden lotus×3 | Golden Lotus | mentions what he did with the first one, vague and unsettling |

### New characters (single visit or short arc)

**Mira** — a kid who comes in once with her dad's money, buys a sunflower, never explains why.
- Trigger: sunflower×1, chapter 1 only
- Plant: Sunflower

**Dottie** — a cheerful regular who becomes the "background warmth" of the shop after a few visits.
- Chapter 1 (lavender×1): first visit, excited to find lavender
- Chapter 2 (lavender×3): returns, says she pressed the last one in a book
- Chapter 3 (lavender×6): brings a pressed flower as a "gift" (flavor text only, no mechanic)

---

## Notes

- Keep anonymous random customers as the fallback — named ones should feel special, not mandatory.
- Don't gate progress behind return customers; they're flavor, not blockers.
- If a character's next chapter trigger isn't met yet, they simply don't appear until it is — no need to force them.
