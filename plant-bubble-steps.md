# Plant Bubble While Held

Goal: fix the water bubble flicker when placing a ready plant. The bubble becomes visible while the cooldown expires but only draws via `store:draw_bubbles()` — so it's invisible while held and suddenly pops in on placement. Showing it while held eliminates the discontinuity.

---

## Step 1 — Draw the held plant's bubble in `Player:draw()`

- [ ] Call `draw_bubble()` on the held item inside `Player:draw()` if the method exists

`Player:draw()` already draws the held item's sprite. Add a `draw_bubble()` call after it:

```lua
function Player:draw()
    self.sprite:draw()
    if self.held_item then
        self.held_item:draw()
        if self.held_item.draw_bubble then
            self.held_item:draw_bubble()
        end
    end
end
```

`draw_bubble()` is a no-op when `bubble.visible` is false, so this is safe for all item types that don't have a bubble, and for plants that aren't ready yet.
