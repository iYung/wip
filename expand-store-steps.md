# Expand Store Steps

Goal: the PC shop sells two things — a plant and a slot expansion. The player spends currency on either. Buying an expansion calls `store:grow()` and a new slot appears at the right end. A sell bin station lets the player sell stage-3 plants for currency.

---

## Mechanic Summary

| Action | Result |
|--------|--------|
| Open shop (F on PC) | BuyScene opens; two options: Plant / Expand Slot |
| A / D in shop | Move cursor between options |
| F on Plant | Deduct `PLANT_COST`, plant goes into player's hand, return to store |
| F on Expand Slot | Deduct `SLOT_COST`, one new slot added at right end, return to store |
| E anywhere in shop | Cancel, return to store |
| F when insufficient funds | Nothing (option shown greyed out) |
| Hold stage-3 plant + E on sell bin slot | Plant sold for `SELL_VALUE`, currency increases, hand emptied |
| Hold non-stage-3 item + E on sell bin slot | Nothing |

---

## Step 1 — Currency

- [x] Add `PLANT_COST = 5`, `SLOT_COST = 10`, and `SELL_VALUE = 5` to `lua/game/config.lua`
- [x] Set `self.currency = 20` in `GameState.new()` (starting funds)
- [x] In `StoreScene:draw()` add a HUD line: `"Currency: " .. gs.currency`

---

## Step 2 — Buy Scene Menu

- [x] Add `self.selected = 1` to `BuyScene.new()`
- [x] A/D navigates between 4 options: Plant, Expand Slot, Watering Can, Grafter
- [x] `_confirm()`: deducts cost and gives item / grows store; does nothing if too poor
- [x] Draw shows all options with prices; highlights selected; greys out unaffordable

---

## Step 3 — Sell Bin

- [x] Created `lua/game/items/sell_bin.lua` — carriable, red sprite, `is_sell_bin = true`
- [x] Selling triggered by F (interact) over sell bin
- [x] Stage-3 plant → `SELL_VALUE`; stage 1-2 plant → 1; tools (watering can, grafter) → 0
- [x] Loaded plant in grafter → sells the loaded plant, resets grafter to empty
- [x] PCStore has `sellable = false`; `sellable = true` is the default on `Item`
- [x] SellBin placed in slot 2

---

## Step 4 — End-to-End Test

- [ ] Open shop with 20 currency — all four options visible and priced
- [ ] Select Plant, buy with F — plant in hand, currency drops by PLANT_COST
- [ ] Grow plant to stage 3, walk to sell bin, press F — currency goes up by SELL_VALUE, hand emptied
- [ ] Open shop, select Expand, buy with F — new slot appears at right end
- [ ] Walk into the new slot, place a plant — confirms slot is live
- [ ] Sell a non-stage-3 plant — currency goes up by 1
- [ ] Drain currency to 0, confirm no buy option fires
- [ ] Press E in shop — returns to store with no change
- [ ] Graft a stage-3 plant, walk to sell bin, press F — loaded plant sold, grafter emptied

---

## Step 5 — Wall Backdrop

Draw a wall rect in `Store:draw()` before the slot loop. The store already knows its total width so it automatically covers new slots when `grow()` is called.

- [ ] In `lua/game/store.lua` `Store:draw()`, before the slot loop:
  - Draw a filled rect: `x=0`, `y=0`, `width=self:width()`, `height=SLOT_Y + SLOT_HEIGHT` (= 800)
  - Color: `{0.15, 0.12, 0.10, 1}` (dark neutral, distinct from slot border brown)

**Future image support:** replace the single rect with a per-slot `wall` Sprite inside `Slot.new()` — each slot draws its own wall panel before its border/bg. Tiles naturally with no store-level changes needed.
