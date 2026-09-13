## Goal

Fix the HUD "SWAP WITH" label to show the **held** item's name, not the hovered slot item's name.

## Affected files

- `lua/game/scenes/store_scene.lua` — line 552, `_hud_labels` method
- `tests/test_swap.lua` — existing swap label tests (need updating to assert correct name)
- `tests/test_hud_labels.lua` — existing hud label tests (need updating to assert correct name)

## What changes

In `store_scene.lua:552`, the label is constructed as:

```lua
up_label = make_label(carry_icon, carry_key, "SWAP WITH " .. slot_item.name:upper())
```

The intent of "SWAP WITH X" is to tell the player what they will be placing down (trading away) — i.e., the item they're currently **holding**. Change it to:

```lua
up_label = make_label(carry_icon, carry_key, "SWAP WITH " .. held.name:upper())
```

The existing tests assert the wrong name (slot item name), so they must be updated to assert the held item's name instead.

## What stays the same

- The swap mechanic itself is unaffected — only the display label changes.
- All other HUD labels remain unchanged.
- Key/icon rendering logic is unchanged.

## Open questions

None.
