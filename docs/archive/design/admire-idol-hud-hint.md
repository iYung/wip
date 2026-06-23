# Design: Admire Idol HUD Hint

## Goal
When the player hovers over the Golden Idol (without holding another item), the bottom-left HUD should display an "ADMIRE" interaction hint — making it clear the idol is interactable and hinting at the action's nature.

## Affected files
- `lua/game/scenes/store_scene.lua` — `_hud_labels()` function

## What changes
Add one more `elseif` branch in `_hud_labels()` inside the `player.x >= 0` block (lines 554–563), checking for the Golden Idol in the active slot:

```lua
elseif not held and slot_item and slot_item.win_scene_factory then
    f_label = make_label(f_icon, f_key, "ADMIRE")
```

Condition mirrors the PCStore pattern (`slot_item.buy_scene_factory`) — the player hovers the idol without holding anything, then presses the interact key. The `win_scene_factory` property is the canonical signal that an item is the Golden Idol.

## What stays the same
- Golden Idol `interact()` implementation is unchanged.
- No new properties or classes needed.
- All other HUD labels (WATER, CLONE, DISCARD, OPEN SHOP) are unaffected.
- The hint disappears automatically when the player picks up the idol (because `held` becomes non-nil), consistent with other items.

## Open questions
None.
