## Tutorial Character + Character Accessories Checklist

- [x] Task A — `lua/game/data/customer_scripts.lua` — Add Sage's 4 chapters and
  add `accessory` fields to all existing scripted characters (Mayor Bloom, The
  Collector, Dottie, Mira). Both changes touch the same file; do them together.

  **Sage entries to add** (append after the existing entries):

  ```lua
  -- Sage (tutorial mentor, 4-chapter arc)
  { id="sage", chapter=1, accessory="straw_hat",
    trigger={ plant_type=1, count=0 },
    name="Sage",
    primary_color={0.35, 0.58, 0.38, 1}, secondary_color={0.55, 0.40, 0.25, 1},
    plant_type=1,
    messages={
      "I've heard there's a new plant shop in town.",
      "Word gets around fast when someone opens up. I had to see for myself.",
      "I'll take a grass. Nothing fancy — just to see how you do.",
    },
  },
  { id="sage", chapter=2, accessory="straw_hat",
    trigger={ plant_type=1, count=3 },
    name="Sage",
    primary_color={0.35, 0.58, 0.38, 1}, secondary_color={0.55, 0.40, 0.25, 1},
    plant_type=1,
    messages={
      "Grass is a good start. But customers want variety.",
      "That computer over there — it's how you get new stock. Check it out.",
      "The more kinds you grow, the more they come.",
    },
  },
  { id="sage", chapter=3, accessory="straw_hat",
    trigger={ plant_type=2, count=1 },
    name="Sage",
    primary_color={0.35, 0.58, 0.38, 1}, secondary_color={0.55, 0.40, 0.25, 1},
    plant_type=2,
    messages={
      "A cactus. Good choice. Takes patience but it pays.",
      "You know about the grafting tool? It copies a finished plant without starting over.",
      "Once you understand that, everything moves faster.",
    },
  },
  { id="sage", chapter=4, accessory="straw_hat",
    trigger={ plant_type=3, count=1 },
    name="Sage",
    primary_color={0.35, 0.58, 0.38, 1}, secondary_color={0.55, 0.40, 0.25, 1},
    plant_type=3,
    messages={
      "A rose. That's real money.",
      "At some point, how fast you move matters as much as what you grow.",
      "Check the upgrades. Speed and heat lamps — they compound.",
    },
  },
  ```

  **Accessory fields to add to existing entries** (add `accessory=` to every
  entry for each character — all chapters of the same character share the same
  accessory string):

  | Character     | Field to add                      |
  |---------------|-----------------------------------|
  | Mayor Bloom   | `accessory = "chain_of_office"`   |
  | The Collector | `accessory = "wide_brim_hat"`     |
  | Dottie        | `accessory = "flower_pin"`        |
  | Mira          | `accessory = "hair_bow"`          |

- [x] Task C — `tests/test_customer_scripts.lua` — Fix tests broken by Sage's
  always-true trigger (`count = 0`). Sage ch1 is now always eligible, so any
  test that calls `_next_customer_cfg()` and asserts a specific character ID
  can non-deterministically return Sage instead of the expected character.

  Fix each affected test by pre-seeding `ctx.gs.seen_scripts` with all Sage
  chapters before calling `_next_customer_cfg()`, so Sage is excluded from
  eligibility for that test's scenario:

  ```lua
  ctx.gs.seen_scripts["sage:1"] = true
  ctx.gs.seen_scripts["sage:2"] = true
  ctx.gs.seen_scripts["sage:3"] = true
  ctx.gs.seen_scripts["sage:4"] = true
  ```

  Tests that need this fix (they assert a specific non-Sage character is
  returned, or that no character is returned):

  | Test | Why it breaks |
  |------|---------------|
  | "scripted customer spawned when trigger met" | expects `old_pete`, Sage now competes |
  | "scripted customer not spawned before trigger count" | expects nil, Sage ch1 always qualifies |
  | "chapter 2 available after chapter 1 seen" | expects `old_pete` ch2, Sage ch1 competes |
  | "seen_scripts written on sale, not on spawn" | asserts `cfg.id == "old_pete"` precondition |
  | "dismiss sets cooldown" | asserts `_script_cooldowns["old_pete:1"]`, breaks if Sage returned |
  | "cooldown decrements per sale, customer returns after 3 sales" | asserts `pete_cfg.id == "old_pete"` precondition |

  `test_golden_lotus.lua` should still pass — `sell_plant()` dismisses
  wrong-type customers and Sage wants grass (type 1) on ch1/ch2, which the
  test is already selling. No changes needed there.

- [x] Task B — `assets/accessories/` — Create placeholder PNGs for the 5 new
  accessories. Each file is 120×120 with a transparent background. Use a
  simple solid-color filled shape so the accessory slot is visually occupied
  until final art is ready. Filenames:

  | File                    | Suggested placeholder color |
  |-------------------------|-----------------------------|
  | `straw_hat.png`         | warm tan / wheat            |
  | `chain_of_office.png`   | gold / yellow               |
  | `wide_brim_hat.png`     | dark charcoal               |
  | `flower_pin.png`        | soft pink / lilac           |
  | `hair_bow.png`          | bright red                  |

  These can be replaced with final art at any time — the game loads them via
  `A.load_accessory()` and draws nothing if a file is absent, so this task is
  independent of Task A.
