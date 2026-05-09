# Shop UI Steps

Goal: redesign BuyScene to show one item at a time. A/D cycles through the catalogue. The center of the screen shows the item name, description, price, and a large item preview. F buys, E cancels.

---

## Mechanic Summary

| Action | Result |
|--------|--------|
| Open shop (F on PC) | BuyScene opens on the last selected item (or item 1) |
| A in shop | Cycle to previous item |
| D in shop | Cycle to next item (wraps around) |
| F on affordable item | Buy it, return to store |
| F on unaffordable item | Nothing |
| E anywhere | Cancel, return to store |

---

## Catalogue (initial)

1. Plant Type 1
2. Watering Can
3. Grafter
4. Expand Slot

Adding plant types 2–6 is handled in [plant-types-steps.md](plant-types-steps.md).

---

## Step 1 — Catalogue Table

- [x] `CATALOGUE` table in `buy_scene.lua` with `label`, `description`, `cost`, `kind`, `plant_type`, `color`
- [x] `self.selected` indexes into `CATALOGUE`; A/D wraps with modulo

---

## Step 2 — Buy Logic

- [x] `_confirm()` switches on `kind` — plant, tool_watering_can, tool_grafter, expand
- [x] Cost per entry; no-op if unaffordable

---

## Step 3 — Draw

- [x] Dark overlay
- [x] Large colored preview rectangle center-screen
- [x] Item name, 2-line description, price (green if affordable, red if not)
- [x] `<` `>` arrows flanking the name
- [x] Index dots below showing position in catalogue
- [x] Currency top-right
- [x] Controls hint at bottom

---

## Step 4 — End-to-End Test

- [x] Cycle through all items with A/D — wraps correctly at both ends
- [x] Each item shows correct name, description, price
- [x] Unaffordable items show red price and don't buy
- [x] Buying each kind gives the right item / effect
- [x] E cancels with no change
