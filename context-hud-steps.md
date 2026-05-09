# Context HUD Steps

Goal: bottom-right HUD that shows context-sensitive labels for E and F, plus the name of whatever is in the active slot. Labels hide when the action isn't available.

---

## Layout

```
              E: PICK UP
              F: OPEN SHOP
        SLOT: WATERING CAN
```

Drawn in screen space, bottom-right corner. Each line only appears when relevant.

---

## Label Rules

### SLOT line
| Condition | Label |
|-----------|-------|
| Slot has an item | `SLOT: <item name>` |
| Slot is empty | hidden |

### E line
| Condition | Label |
|-----------|-------|
| Holding nothing, slot has carriable item | `E: PICK UP` |
| Holding item, slot is empty | `E: PUT DOWN` |
| Holding loaded grafter, slot is empty | `E: PLACE CLONE` |
| Otherwise | hidden |

### F line
| Condition | Label |
|-----------|-------|
| Holding nothing, slot has PC Store | `F: OPEN SHOP` |
| Holding watering can, slot has any plant | `F: WATER` |
| Holding unloaded grafter, slot has stage-3 plant | `F: CLONE` |
| Holding any sellable item, slot has sell bin | `F: SELL` |
| Otherwise | hidden |

---

## Step 1 — Item Names

- [ ] Add a `name` field to each item's `new()`:
  - `WateringCan` → `"Watering Can"`
  - `Plant` → `"Plant"` (or `"Plant (stage N)"` — decide)
  - `Grafter` → `"Grafter"`
  - `PCStore` → `"PC Store"`
  - `SellBin` → `"Sell Bin"`

---

## Step 2 — Context Resolver

- [ ] Add `StoreScene:_hud_labels()` — returns `{ slot, e, f }` strings (nil = hidden):
  - Derive `player`, `slot`, `held` from game state
  - Apply the rules from the table above
  - Return the three strings (any can be nil)

---

## Step 3 — Draw

- [ ] In `StoreScene:draw()`, call `_hud_labels()` and print non-nil lines stacked bottom-right
  - Anchor to e.g. `x=1260, y=680` and step upward per line
  - Use right-aligned text or fixed right margin

---

## Step 4 — End-to-End Test

- [ ] Empty hands, empty slot — all three lines hidden
- [ ] Empty hands, over watering can — `E: PICK UP`, `SLOT: WATERING CAN`
- [ ] Holding watering can, over plant slot — `E: PUT DOWN`, `F: WATER`
- [ ] Holding watering can, over empty slot — `E: PUT DOWN`
- [ ] Empty hands, over PC Store — `E: PICK UP`, `F: OPEN SHOP`
- [ ] Holding loaded grafter, over empty slot — `E: PLACE CLONE`
- [ ] Holding stage-3 plant, over sell bin — `F: SELL`, `SLOT: SELL BIN`
- [ ] Holding PC Store — F line hidden
