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

### Player Interaction

- The player can **pick up** the item in the active slot
- The player can **place** a held item into the active slot
- Only one item held at a time
- **Interact** triggers item use (e.g. watering can waters the slot) or station actions (e.g. PC store opens BuyScene)

### Store Growth

The player can increase the number of slots. Adding a slot expands the store width by one `slot_width`. New slots are added at one end only (which end TBD).

---

## Items

### Watering Can

- Can be picked up and carried
- Player uses it on the slot they are standing in
- Waters the plant in that slot (advances growth)

### Grafter

- Can be picked up and used on a slot
- Clones the plant in that slot into the held item slot (TBD — exact mechanic to define)

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

Plant types (names TBD):

| # | Type |
|---|------|
| 1 | TBD  |
| 2 | TBD  |
| 3 | TBD  |
| 4 | TBD  |
| 5 | TBD  |
| 6 | TBD  |

Each growth stage has a cooldown timer. When the timer reaches zero the plant is ready to be watered. Watering a ready plant advances it to the next stage and resets the timer for the new stage. Watering a plant that is not ready does nothing.

When a plant is ready, a speech bubble appears above it as a visual indicator.

---

## Scenes

| Scene      | Description                                         |
|------------|-----------------------------------------------------|
| StoreScene | Main gameplay — player moves in the store           |
| BuyScene   | Full scene swap; browse and buy plants, then return |

---

## Open Questions

- Which end does the store expand from — left or right?
- What does the grafter produce — a copy of the plant, or a cutting to plant elsewhere?
- How many waterings per growth stage?
- What happens when a plant reaches Done — is it harvested for currency?
- What are the 6 plant types?
- Is there a win condition or is it an idle/loop game?
