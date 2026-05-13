# Rename Fern to Grass

**File:** `lua/game/data/plant_data.lua` — line 3

```lua
-- change:
name = "Fern",

-- to:
name = "Grass",
```

That's the only place the name appears. The description on line 4 can be updated too if needed.

---

# Plant Name Reconsideration

> **Before implementing:** check in with the user to decide the final plant names first.


Two other plants need new names. Changes are all in `lua/game/data/plant_data.lua` — just `name` and `description`.

## Sunflower (plant 4) — too similar to Golden Lotus

Both are yellow at stage 3. Sunflower reads as a warm/cheerful mid-tier but visually clashes with the lotus. Options to consider:

| Name | Feel |
|---|---|
| Tulip | Iconic, colorful, clearly distinct |
| Marigold | Warm orange-yellow, very recognizable |
| Daffodil | Bright yellow but softer than sunflower |
| Poppy | Bold, vivid, well-known |

## Lavender (plant 5) — not well-known enough

It's a purple high-value plant. Options that are more recognizable and still purple/violet:

| Name | Feel |
|---|---|
| Orchid | Premium, exotic — fits the high sell price |
| Wisteria | Romantic, visually distinct cascading flower |
| Violet | Simple, iconic color name |
| Iris | Elegant, well-known purple flower |

Note: whichever names are chosen, also check `customer_scripts.lua` — Dottie's chapter references lavender by name in her dialog lines.
