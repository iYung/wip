## Goal

Remove Wallace chapter 4 (the "raccoons burned the house down / Golden Lotus" visit) entirely. Wallace becomes a 3-chapter arc ending with the second raccoon.

## Affected files

- `lua/game/data/customer_scripts.lua` — remove the chapter 4 entry
- `tests/test_customer_scripts.lua` — remove all `wallace:4` references and any tests specific to it
- `tests/test_quest_timing.lua` — remove the `wallace:4` contribution from the Lotus trigger timing table

## What changes

- The chapter 4 block (lines ~809–829 in `customer_scripts.lua`) is deleted.
- The stale comment on line 745 is updated: "3-chapter arc" is already correct (was wrong before because chapter 4 existed); the plant chain annotation becomes "rose → daisy → daisy".
- Any test setup that pre-marks `wallace:4` as seen is removed. A dedicated chapter-4 trigger test does not exist, so no test logic needs to be replaced.
- The quest-timing table entry that attributes Lotus-1 to `wallace:4` is removed or updated.

## What stays the same

- Chapters 1–3 and their triggers are untouched.
- The `prior_ok` chain check in `store_scene.lua` is untouched.
- Save compatibility: existing saves that have `seen_scripts["wallace:4"] = true` will simply carry a key that no script ever references — harmless.

## Open questions

None.
