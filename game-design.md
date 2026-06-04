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
| `F: OPEN SHOP` | Empty hands, over PC Store |
| `F: WATER` | Holding watering can, over a plant |
| `F: CLONE` | Holding grafter, over a stage-3 plant |
| `F: DISCARD` | Holding any sellable item, over garbage bin |
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
- Using it (F) on a slot with a stage-3 plant: resets the original plant to stage 1 and immediately spawns a clone into the nearest empty slot (ties broken by lower index)
- If no empty slot is available, a no-space bubble appears above the grafter for 1.5 s and the source plant is untouched
- Does nothing if the target slot has no stage-3 plant

### Garbage Bin

- Can be picked up and placed
- Player presses Interact (F) while holding any sellable item over the bin to discard it
- PC Store cannot be discarded

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
| 1 | Grass | $0 | $3 | 1s, 1s |
| 2 | Cactus | $9 | $15 | 8s, 12s |
| 3 | Rose | $150 | $50 | 6s, 9s |
| 4 | Tulip | $60 | $90 | 4s, 7s |
| 5 | Daisy | $90 | $140 | 3s, 5s |
| 6 | Golden Lotus | $500 | $800 | 2s, 3s |

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
| Sir Moneyton | Grass → Cactus → Expand → Grafter | 4 | Guaranteed first customer; teaches cactus, store expansion, then grafter (after roses — because roses are expensive, grafting is how you scale them); wears a monocle |
| Mayor Bloom | Rose | 2 | Formal first visit; returns privately for himself; wears secretary glasses |
| Agent Frogsby | Cactus → Rose | 2 | Comedy spy; buys cactus for close-quarters combat, returns needing rose thorns as barbed wire (pulls toward rose); wears a coat — *coat.png asset needed* |
| Mira | Tulip | 2 | Kid with her dad's money; shows up after roses to buy a tulip (pulls toward tulip); forgets one more later |
| Dottie | Daisy | 3 | Cheerful regular; presses flowers in books; brings one back as a gift; wears a flower pin |
| Mechafrog | Daisy → Grass | 2 | Recently unemployed robot; their org was defeated by a prickly ball and barbed wire (Frogsby); seeks forgiveness via daisy (pulls toward daisy); returns later as a gardener wanting grass; wears an antenna — *antenna.png asset needed* |
| The Collector | Golden Lotus | 2 | Mysterious; shows up after 30 daisies asking for golden lotus (pulls toward lotus); hints at what he did with the first one; wears shades |

**Pull characters by plant tier:**

| Plant | Pull character | Trigger |
|-------|---------------|---------|
| Cactus | Sir Moneyton Ch2 | grass stage3 ≥ 3 |
| Rose | Agent Frogsby Ch2 | cactus stage3 ≥ 4 |
| Tulip | Mira Ch1 | rose stage3 ≥ 3 |
| Daisy | Mechafrog Ch1 | daisy stage3 ≥ 3 |
| Golden Lotus | The Collector Ch1 | daisy stage3 ≥ 30 |

**Dialog flow:**
- Scripted customers: F advances through messages one at a time; after the last message the plant-image bubble appears
- Random customers: no dialog — plant bubble appears immediately on arrival
- Once the plant bubble is showing, F while holding the correct stage-3 plant completes the sale
- After the sale, scripted characters may say additional lines (`after_messages`); F advances through them; after the last line the heart bubble appears and they walk out
- While the typewriter is revealing text, each character's voice plays as a pitched sample (animalese); skipping a line is silent since it jumps the index instantly; each character has a unique `voice_pitch` tuned to their personality

**Sale:**
- Pays **2× normal sell value**
- After sale: customer walks back out to the left and disappears
- Next customer spawns after a random delay once the previous has fully exited

### Cashier Rules

- E key does nothing in the cashier zone (no putting items down)
- E normally dismisses the current customer (they walk out and return after 3 other sales); the first quest (Sir Moneyton ch1) is undismissable — E is blocked and the "E: DISMISS" HUD label is hidden until the player completes or the session ends
- F only triggers dialog/sale when the customer has fully arrived (`waiting` state)
- Sale value shown live in the context HUD: `F: SELL TO CUSTOMER ($X)`

---

## Upgrades

### Speed Boost

Purchasable in the shop. Three tiers, each permanently increasing player movement speed. Each tier also applies a color (via shader) to the pure-red mask area of the player sprite.

| Tier | Cost | Speed | Color |
|------|------|-------|-------|
| 1 | $15 | 320 px/s | light blue |
| 2 | $40 | 480 px/s | orange/gold |
| 3 | $100 | 720 px/s | purple |

---

## Scenes

| Scene         | Description                                         |
|---------------|-----------------------------------------------------|
| StartScene    | Title screen with New Game / Continue / Settings / Exit buttons; up/down to navigate, Enter/Space/F to confirm |
| SettingsMenu  | Pause overlay (not a Scene subclass); Fullscreen toggle, Exit Settings, Leave Game; opened via Esc in gameplay scenes or Settings button on start screen |
| StoreScene    | Main gameplay — player moves in store and cashier zone |
| BuyScene      | Full scene swap; browse and buy items (Plant, Expand, Watering Can, Grafter) |

---

## Open Questions

- Is there a win condition or is it an idle/loop game?
- Should customers have a patience timer and leave if not served?
