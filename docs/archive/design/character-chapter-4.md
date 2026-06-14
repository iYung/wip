# Character Chapter 4

## Goal

Add a fourth chapter to the 8 characters that currently have 3 chapters. Sage already has 4; The Collector and Mira stay at 2.

Characters receiving ch4: mayor_bloom, romeo, agent_frogsby, dottie, glen, wallace, chef_brio, mechafrog.

## Affected files

- `lua/game/data/customer_scripts.lua` — new script entries
- `tests/test_quest_timing.lua` — update schedule comment, add new trigger targets if needed

## What changes

Eight new script entries appended to `customer_scripts.lua`, each continuing the established character voice. Triggers use existing plant counts already reached by the timing test schedule (all ≤ the current schedule's targets). The test schedule itself does not need to be extended; only its inline comments need updating.

## Spacing

Current timeline ends at ~120m. The 8 new chapters are spread across the daisy era (~60–78m), the lotus era (~90–93m), and a late final slot at ~119m for mechafrog. Each new chapter falls after that character's ch3 trigger by a comfortable margin.

| Character | Trigger | ~Time | Plant req | Story beat |
|---|---|---|---|---|
| romeo | Daisy ≥ 8 | ~60m | Rose (3) | 6 months together, proposing tonight |
| agent_frogsby | Daisy ≥ 12 | ~64m | Daisy (5) | Going undercover in a garden society |
| mayor_bloom | Daisy ≥ 16 | ~69m | Golden Lotus (6) | Won the election — decorating the office |
| dottie | Daisy ≥ 20 | ~73m | Tulip (4) | Performing at the mayor's inauguration, love scene in the act |
| glen | Daisy ≥ 24 | ~78m | Cactus (2) | Back on Joe Froggan — new episode says cactus was right all along |
| wallace | Lotus ≥ 1 | ~90m | Golden Lotus (6) | Raccoon count now 3. Wife moved out. Desperate plea |
| chef_brio | Lotus ≥ 3 | ~93m | Golden Lotus (6) | Nominated for Frog Chef Awards — going all in with lotus bread |
| mechafrog | Lotus ≥ 5 | ~119m | Grass (1) | Garden won Frogtown's Best Scenic award — ceremonial grass to mark the moment |

## What stays the same

- sage, the_collector, mira — chapter counts unchanged
- All trigger mechanics (chapter gating, seen_scripts, cooldown system)
- Test schedule targets and structure — only inline comments change
- No new plant types or game mechanics

## Open questions

None — resolved with user:
- The Collector and Mira stay at 2 chapters
- Plant types chosen by story fit, mixed across tiers
