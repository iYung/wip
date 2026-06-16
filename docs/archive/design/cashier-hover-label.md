# Design: Cashier Zone Hover Label

## Goal

Show a "HOVERING" label in the bottom-left HUD when the player is in the cashier zone and a stationary customer is present. Use the customer's name for scripted customers, and "CUSTOMER" for generic ones. Suppress the label while the customer is walking.

## Affected files

- `lua/game/scenes/store_scene.lua` — `_hud_labels()` function (line 449)

## What changes

In `_hud_labels()`, `slot_label` is currently only set when `player.x >= 0` (store side). The cashier side (`player.x < 0`) produces no hover label at all.

Add a cashier-side branch that sets `slot_label` when:
- `self._customer` exists and is active (state ≠ `"idle"`)
- Customer is **not** moving (state ≠ `"walking_in"` and ≠ `"walking_out"`)

Label text:
- Scripted (named) customer: `"HOVERING " .. customer.name:upper()`
  - Detection: `customer.name ~= "Customer"` (generic customers default to `"Customer"`)
- Generic customer: `"HOVERING CUSTOMER"`

## What stays the same

- Store-side hover label (slot items) is unchanged.
- All cashier E/F key labels are unchanged.
- Customer state machine is unchanged.
- No new fields added to Customer.

## Open questions

None.
