# Tutorial Character + Character Accessories — Design Doc

## Goal

Two related additions:

1. Add a 4-chapter scripted character ("Sage") who walks the player through
   the game's core mechanics. Sage is the guaranteed first customer — she
   arrives before any plants are grown, introduces herself, and requests a
   grass. Growing and selling it to her teaches the core loop naturally.

2. Give every scripted character an accessory. Accessories are the visual
   signal that distinguishes a scripted customer from a random one — the
   player should be able to tell at a glance that someone is worth talking
   to. Old Pete already has `flat_cap`. All others need one.

Both additions are data + art only — no code changes.

---

## Affected files

- `lua/game/data/customer_scripts.lua` — add 4 Sage chapter entries; add
  `accessory` field to Mayor Bloom, The Collector, Dottie, and Mira entries
- `assets/accessories/` — add 5 new PNG files (one per character)
- `tests/test_customer_scripts.lua` — fix tests that assert specific character
  IDs from `_next_customer_cfg()`; Sage's `count = 0` trigger makes her always
  eligible and breaks those assertions

---

## What changes

---

### New character: Sage

A warm, experienced plant trader who has clearly been around the trade for
years. She visits early and returns as the player grows — each time pointing
out something new without being preachy. Her advice is observational: she
notices what the player has done and nudges the next step.

**Visual identity**

| Property         | Value                                      |
|------------------|--------------------------------------------|
| `id`             | `"sage"`                                   |
| `name`           | `"Sage"`                                   |
| `primary_color`  | `{0.35, 0.58, 0.38, 1}` — muted sage green |
| `secondary_color`| `{0.55, 0.40, 0.25, 1}` — warm earth brown |
| `accessory`      | `"wide_brim_hat"` — a well-worn gardening hat; fits a long-time grower |

---

#### Chapter 1 — First contact

**Trigger:** `{ plant_type = 1, count = 0 }` — always true. Sage is the only
eligible scripted character at game start, so she is guaranteed to be the
first customer.

The player has no stage-3 plants yet when she arrives. After her dialog the
grass bubble appears; the player must grow one to serve her, teaching the
core loop by requiring it.

**Dialog:**
```
"I've heard there's a new plant shop in town."
"Word gets around fast when someone opens up. I had to see for myself."
"I'll take a grass. Nothing fancy — just to see how you do."
```

**Buys:** grass (type 1) — **Teaches:** grow → water → sell loop

---

#### Chapter 2 — Variety

**Trigger:** `{ plant_type = 1, count = 3 }` — fires after 3 grass plants have
reached stage 3. Player has the loop down; time to push toward new stock.

**Dialog:**
```
"Grass is a good start. But customers want variety."
"That computer over there — it's how you get new stock. Check it out."
"The more kinds you grow, the more they come."
```

**Buys:** grass (type 1) — **Teaches:** PC Store / buying new plant types

---

#### Chapter 3 — The grafter

**Trigger:** `{ plant_type = 2, count = 1 }` — fires after the player's first
cactus reaches stage 3.

**Dialog:**
```
"A cactus. Good choice. Takes patience but it pays."
"You know about the grafting tool? It copies a finished plant without starting over."
"Once you understand that, everything moves faster."
```

**Buys:** cactus (type 2) — **Teaches:** the grafter / clone-to-expand workflow

---

#### Chapter 4 — Efficiency

**Trigger:** `{ plant_type = 3, count = 1 }` — fires after the player's first
rose reaches stage 3.

**Dialog:**
```
"A rose. That's real money."
"At some point, how fast you move matters as much as what you grow."
"Check the upgrades. Speed and heat lamps — they compound."
```

**Buys:** rose (type 3) — **Teaches:** speed + heat lamp upgrades

---

### Accessories for existing recurring characters

The `accessory` string in each script entry is passed to `A.load_accessory()`,
which loads `assets/accessories/<name>.png` (120×120, transparent background)
and draws it over the character's top half. Old Pete's `flat_cap` is the
reference implementation.

All chapters of the same character share the same accessory — the field is
on every entry for that character.

---

#### Mayor Bloom — `"chain_of_office"`

A formal mayoral chain worn across the chest. Signals civic authority,
matches Bloom's stiff first visit and vulnerable second.

---

#### The Collector — `"wide_brim_hat"`

A dark, well-traveled wide-brim hat. Suggests long journeys, reinforces the
air of mystery, fits the Golden Lotus obsession.

| Character     | Accessory key        | Description                          |
|---------------|----------------------|--------------------------------------|
| Sage          | `"straw_hat"`        | Worn straw gardening hat             |
| Mayor Bloom   | `"chain_of_office"`  | Formal mayoral chain across the chest|
| The Collector | `"wide_brim_hat"`    | Dark, well-traveled wide-brim hat    |
| Dottie        | `"flower_pin"`       | Small pressed flower pinned to lapel — a nod to her book-pressing habit |
| Mira          | `"hair_bow"`         | A child's hair bow — immediately reads as a kid, fits her "dad's money" line |

---

## What stays the same

- No changes to `customer.lua`, `store_scene.lua`, `game_state.lua`, or any
  other file.
- Accessories gracefully no-op if the PNG is missing (`A.load_accessory`
  caches `false` on missing files; `draw()` skips the accessory sprite).
- Sage competes with other scripted characters normally after chapter 1.
  She is not prioritised beyond the always-true trigger on chapter 1.

---

## Open questions

None.
