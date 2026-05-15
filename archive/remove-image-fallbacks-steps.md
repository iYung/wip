# Remove Image Fallbacks

Goal: assume all images exist. Replace all `try_img` calls with `img`, remove nil-checks at draw sites, and delete the redundant `{1,1,1,1}` color assignments.

---

## Step 1 — `assets.lua`: replace `try_img` with `img`

Change these six lines from `try_img` to `img`:

```lua
A.slot_highlight     = img("assets/slot_highlight.png")
A.store_bg_far       = img("assets/shop_bg_far.png")
A.store_bg_mid       = img("assets/shop_bg_mid.png")
A.store_bg_near      = img("assets/shop_bg_near.png")
A.speech_bubble      = img("assets/speech_bubble.png")
A.speech_bubble_tail = img("assets/speech_bubble_tail.png")
```

Then delete the `try_img` helper function entirely.

---

## Step 2 — `slot.lua`: remove nil-check on `slot_highlight`

Before:
```lua
if self.highlighted and A.slot_highlight then
    love.graphics.draw(A.slot_highlight, ...)
end
```

After:
```lua
if self.highlighted then
    love.graphics.draw(A.slot_highlight, ...)
end
```

---

## Step 3 — `customer.lua`: remove nil-checks on speech bubble assets

Two draw sites, both use `if A.speech_bubble` / `if A.speech_bubble_tail` guards. Remove the guards and draw unconditionally.

---

## Step 4 — Remove redundant `{1,1,1,1}` color assignments

These are no-ops since `{1,1,1,1}` is the sprite default. Delete the `.color` lines from:

- `player.lua` — all four sprite definitions (idle, walk, idle_held, walk_held)
- `watering_can.lua`
- `grafter.lua`
- `pc_store.lua`
- `garbage_bin.lua`
