# Design: DJ Frogga

## Goal

Add a new 2-chapter customer arc for DJ Frogga — a hype DJ who visits the shop each time to get inspo for a sick beat. Speaks entirely in ALL CAPS. Wears shades. Wants a cactus in chapter 1, a tulip in chapter 2.

## Character

| Field | Value |
|-------|-------|
| `id` | `dj_frogga` |
| `name` | `DJ Frogga` |
| `accessory` | `shades` (reuses existing asset, already used by The Collector) |
| `voice_pitch` | `1.10` |
| `primary_color` | `{0.50, 0.15, 0.75, 1}` (deep purple) |
| `secondary_color` | `{0.15, 0.90, 0.60, 1}` (neon green) |

## Arc

| Chapter | Trigger | Wants | Theme |
|---------|---------|-------|-------|
| 1 | cactus sold ≥ 15 | Cactus (plant_type 2) | Needs spiky inspo for a new drop |
| 2 | tulip sold ≥ 17 | Tulip (plant_type 4) | Back for smooth inspo after the last track blew up |

## Dialogue

**Chapter 1** (`trigger = { plant_type = 2, count = 15 }`):
```
messages = {
    "Yo, what's good!",
    "I'm DJ Frogga, the hottest DJ in Frogtown right now.",
    "I'm working on the sickest beat and I need some inspo.",
    "You got something spiky with a little attitude?",
}
after_messages = {
    "Yooo, this is it. I can feel the beat already.",
}
```

**Chapter 2** (`trigger = { plant_type = 4, count = 17 }`):
```
messages = {
    "Yo, it's me, DJ Frogga!",
    "My last track went crazy. Frogs were jumping on the drop.",
    "Now I'm working on something softer. Something smooth.",
    "You got something for inspo? I need something that sends those smooth vibes over to me.",
}
after_messages = {
    "Oooh yes. The vibes are immaculate.",
}
```

## Affected files

- `lua/game/data/customer_scripts.lua` — add 2 new entries for `dj_frogga`
- `tests/test_customer_scripts.lua` — add 4 tests (ch1 spawns at count ≥ 15, doesn't spawn before; ch2 spawns at count ≥ 17 after ch1 seen, doesn't spawn before ch1 seen)

## What changes

Add two new entries to `customer_scripts.lua` after the `wallace` block. No new assets, no scene changes, no save format changes.

## What stays the same

- Trigger system in `store_scene.lua` — unchanged
- Chapter sequencing logic — chapter 2 already requires chapter 1 seen
- `shades.png` asset — shared with The Collector, no changes needed
- `GameState`, save/load — unchanged

## Open questions

None.
