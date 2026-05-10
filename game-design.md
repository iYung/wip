# Game Design Document

## Overview

A side-scrolling plant growing game. No jumping. The player tends a store by moving left and right, growing plants from seed to completion.

---

## Camera

The camera always centers on the player character. As the player moves, the store scrolls with them.

---

## Store Scene

The main gameplay scene.

### Layout

The store is a **1D array of slots**. Each slot is one column wide. The store's total width = `slot_count × slot_width`.

```
[ slot 0 ][ slot 1 ][ slot 2 ][ slot 3 ] ...
```

The player moves freely left and right as a separate visual layer rendered on top of the store. The **active slot** is whichever slot the player is currently standing over, derived from the player's x position.

### Controls

| Button       | Action                                              |
|--------------|-----------------------------------------------------|
| Move Left    | Move player left                                    |
| Move Right   | Move player right                                   |
| Pick Up/Down | Pick up item from active slot, or place held item   |
| Interact     | Use held item on active slot, or interact with station |

### Context HUD

Bottom-left overlay showing context-sensitive labels. Each line only appears when the action is available.

| Line | When shown |
|------|-----------|
| `HOVER: <name>` | Player is over a slot with an item |
| `E: PICK UP` | Empty hands, slot has a carriable item |
| `E: PUT DOWN` | Holding an item, slot is empty |
| `E: PLACE CLONE` | Holding a loaded grafter, slot is empty |
| `F: OPEN SHOP` | Empty hands, over PC Store |
| `F: WATER` | Holding watering can, over a plant |
| `F: CLONE` | Holding unloaded grafter, over a stage-3 plant |
| `F: SELL ($X)` | Holding any sellable item, over sell bin |
| `F: NEXT` | In cashier zone, customer waiting, still in dialog |
| `F: SELL TO CUSTOMER ($X)` | In cashier zone, customer done talking, holding the requested stage-3 plant |

### Player Interaction

- The player can **pick up** the item in the active slot
- The player can **place** a held item into the active slot
- Only one item held at a time
- **Interact** triggers item use (e.g. watering can waters the slot) or station actions (e.g. PC store opens BuyScene)

### Store Growth

The player can increase the number of slots. Adding a slot expands the store width by one `slot_width`. New slots are added at the **right end**.

---

## Items

### Watering Can

- Can be picked up and carried
- Player uses it on the slot they are standing in
- Waters the plant in that slot (advances growth)

### Grafter

- Can be picked up and carried
- Has two states: **empty** and **loaded**
- Using it (F) on a slot with a plant: resets the original plant to stage 1, stores a clone inside the grafter (loaded state)
- Putting it down (E) over an empty slot while loaded: places the clone into that slot; grafter empties and stays in the player's hand
- Does nothing if already loaded, or if the target slot has no plant

### Sell Bin

- Can be picked up and placed
- Player presses Interact (F) while holding an item over the sell bin to sell it
- Sale values: stage-3 plant → `SELL_VALUE`; stage 1–2 plant → 1; tools → 0
- Selling a loaded grafter sells the stored plant clone and empties the grafter
- PC Store cannot be sold

---

### PC Store

- Can be picked up and carried
- Player interacts with it only when it is placed in a slot (not while held) to trigger a scene switch to BuyScene
- On exit from BuyScene, switches back to StoreScene

### Plants

6 plant types, each with 3 growth stages:

| Stage | Name    | Description                        |
|-------|---------|------------------------------------|
| 1     | Baby    | Just planted, small                |
| 2     | Growing | Mid stage, visibly developing      |
| 3     | Done    | Fully grown, ready to harvest      |

Plant types:

| # | Name | Cost | Sell | Cooldowns |
|---|------|------|------|-----------|
| 1 | Fern | $1 | $5 | 10s, 15s |
| 2 | Cactus | $3 | $8 | 8s, 12s |
| 3 | Rose | $6 | $13 | 6s, 9s |
| 4 | Sunflower | $10 | $20 | 4s, 7s |
| 5 | Lavender | $15 | $28 | 3s, 5s |
| 6 | Golden Lotus | $20 | $40 | 2s, 3s |

Each growth stage has a cooldown timer. When the timer reaches zero the plant is ready to be watered. Watering a ready plant advances it to the next stage and resets the timer for the new stage. Watering a plant that is not ready does nothing.

When a plant is ready, a speech bubble appears above it as a visual indicator.

---

---

## Cashier Zone

A walkable zone to the left of the store (x = -400 to 0). Visually separated by a wall with a window cutout.

### Layout

```
[ cashier zone (400px) ][ slot 1 ][ slot 2 ] ...
x = -400               x = 0
```

### Customer

Two kinds of customers can spawn:

**Scripted customers** — defined in `customer_scripts.lua`. Each entry has an `id`, a `chapter` number, and a `trigger` (a plant type must have reached stage 3 a minimum number of times). Characters with the same `id` are chapters of the same person. Chapter 2 won't appear until chapter 1 has been seen, and so on. Among all currently eligible chapters, one is picked at random — multiple characters can qualify at the same time. Scripted customers have a unique name, body color, multi-line dialog, and an optional accessory sprite drawn over their top half.

**Random customers** — pick a plant type uniformly at random from all plants the player has unlocked (purchased). Fern is unlocked from the start. Random customers spawn whenever no scripted chapter qualifies.

**Named characters and their arcs:**

| Character | Plant | Chapters | Arc |
|-----------|-------|----------|-----|
| Old Pete | Cactus | 3 | Gruff regular who warms up over time; wears a flat cap |
| Mayor Bloom | Rose | 2 | Formal first visit; returns privately for himself |
| The Collector | Golden Lotus | 2 | Mysterious; hints at what he did with the first one |
| Mira | Sunflower | 1 | Kid with her dad's money, no explanation |
| Dottie | Lavender | 3 | Cheerful regular; presses flowers in books; brings one back as a gift |

**Dialog flow:**
- Scripted customers: F advances through messages one at a time; after the last message the plant-colored bubble appears
- Random customers: no dialog — plant bubble appears immediately on arrival
- Once the plant bubble is showing, F while holding the correct stage-3 plant completes the sale

**Sale:**
- Pays **2× normal sell value**
- After sale: customer walks back out to the left and disappears
- Next customer spawns after a random delay once the previous has fully exited

### Cashier Rules

- E key does nothing in the cashier zone (no putting items down)
- F only triggers dialog/sale when the customer has fully arrived (`waiting` state)
- Sale value shown live in the context HUD: `F: SELL TO CUSTOMER ($X)`

---

## Upgrades

### Speed Boost *(planned)*

Purchasable in the shop. Three tiers, each permanently increasing player movement speed.

| Tier | Cost | Speed |
|------|------|-------|
| 1 | $10 | 280 px/s |
| 2 | $20 | 340 px/s |
| 3 | $35 | 400 px/s |

---

## Scenes

| Scene      | Description                                         |
|------------|-----------------------------------------------------|
| StoreScene | Main gameplay — player moves in store and cashier zone |
| BuyScene   | Full scene swap; browse and buy items (Plant, Expand, Watering Can, Grafter) |

---

## Open Questions

- Is there a win condition or is it an idle/loop game?
- Should customers have a patience timer and leave if not served?
