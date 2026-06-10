## Goal

Add a headless test (`tests/test_quest_sales.lua`) that simulates a full playthrough and reports, for each chapter trigger, the total number of plant sales that had occurred when that chapter first became eligible. This gives a "sales pacing" view of the chapter unlock curve — a balance tool surfaced as a test so it runs in CI and stays up to date automatically.

## Affected files

- `tests/test_quest_sales.lua` — new file (the only change)

## What changes

**New file: `tests/test_quest_sales.lua`**

Runs the same grow-and-sell simulation loop already established in `test_quest_timing.lua` (same `schedule` table, same `walk_to` / `sell_plant` helpers, same `check_milestones` pattern), but instead of recording `elapsed` seconds it records `total_sales` — a simple integer counter incremented once per completed cashier sale (any plant type, any customer).

Output table (printed to stdout):

```
[quest-sales] chapter unlock curve  (total sales at trigger, single slot):
  name                  ch    sales   trigger
  -------------------------------------------------------
  Sage                  ch1       0   Grass >= 0
  Sage                  ch2       3   Cactus >= 3
  ...
  -------------------------------------------------------
  All chapters by: 143 sales
```

A final `assert` checks that every chapter in `customer_scripts.lua` appears in the milestones table (same guard as `test_quest_timing.lua`) so the test fails if the schedule misses a trigger, keeping CI honest.

## What stays the same

- `test_quest_timing.lua` is not touched — the new file is fully independent.
- The simulation strategy (single slot, one plant type at a time, sequential schedule) mirrors what's already in `test_quest_timing.lua` so the two reports stay comparable.
- `stage3_counts` semantics unchanged — triggers still fire on grow-to-stage-3, not on sale; `total_sales` is the count of cashier transactions that have completed at the moment the trigger fires.
- No new helpers or shared modules needed; helpers are local to the test file.

## Open questions

None — all resolved before writing this doc.
- Sales metric: total sales across all plant types.
- Location: `tests/test_quest_sales.lua` (runs in CI headless suite).
