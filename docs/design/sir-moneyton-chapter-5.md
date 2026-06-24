# Design: Sir Moneyton Chapter 5

## Goal

Add a fifth chapter to the Sir Moneyton (`sage`) customer arc. Triggers when the player has sold 5 roses at stage 3, and Sir Moneyton returns wanting a cactus.

## Context: Existing Arc

| Chapter | Trigger | Wants | Purpose |
|---------|---------|-------|---------|
| 1 | 0 grass sold | Grass | Tutorial: buy, water, sell |
| 2 | 3 grass sold | Cactus | Tutorial: buy variety |
| 3 | 4 cacti sold | Cactus | Tutorial: upgrade slots |
| 4 | 1 rose sold | Rose | Tutorial: grafter |
| 5 *(new)* | 5 roses sold | Cactus | TBD (see open questions) |

## What Changes

**Only one file:** `lua/game/data/customer_scripts.lua`

Add a new entry at the end of the `sage` block (after chapter 4, before Romeo):

```lua
{
    id             = "sage",
    chapter        = 5,
    accessory      = "monocle",
    trigger        = { plant_type = 3, count = 5 },
    name           = "Sir Moneyton",
    voice_pitch    = 0.88,
    primary_color     = {0.35, 0.58, 0.38, 1},
    secondary_color = {0.55, 0.40, 0.25, 1},
    plant_type     = 2,
    messages       = {
        "The shop looks excellent! You've really found your rhythm.",
        "Though I notice you're still on your original shoes.",
        "Your laptop has a speed upgrade. Faster feet means faster deliveries.",
        "Oh, and can I take a cactus? I need one for my office window.",
    },
    after_messages = {
        "Thank you! And truly, look through your laptop. There are more upgrades than just the shoes.",
    },
},
```

All other fields (accessory, colors, voice_pitch) copy from existing sage chapters exactly.

## What Stays the Same

- Trigger system in `store_scene.lua` — no changes needed
- Chapter sequencing logic — chapter 5 already requires chapters 1–4 to be seen first
- `GameState`, save/load — no changes needed
- No new assets needed

## Open Questions

~~1. **Dialogue**~~ — Resolved: hints shoe speed upgrades from the laptop; after_messages nudges toward other upgrades.
