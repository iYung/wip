## Goal

Replace the hardcoded schedule in `test_quest_sales.lua` with a customer-driven simulation. Instead of grinding one plant type at a time, the test reacts to whoever arrives: if the customer wants a plant we can grow, we grow it and sell it; if not, we dismiss them.

## Affected files

- `tests/test_quest_sales.lua` — full rewrite

## What changes

### Plant availability

- Start with only grass available: `available = { [1] = true }`
- When a chapter milestone fires, check the chapter's `plant_type` (what the customer buys). If that type isn't in `available` yet, add it and set `ctx.gs.unlocked_plants[pt] = true` so the game starts routing those customers.
- No currency gating — chapters are the unlock gate, not money.

### Main loop (replaces the hardcoded `schedule`)

```
repeat
    wait for customer to arrive
    X = customer's plant_type
    if available[X]:
        swap Plant.new(X) into slot 4
        grow it (water twice, wait for ready each time)
        sell at cashier
        record sale in sales / earned / sales_by_pt
        check_milestones → unlock any newly introduced plants
    else:
        dismiss customer
until all chapter keys are in milestones
```

### Milestone snapshot

`current_pt` (the plant being ground at that moment) no longer exists. Replace with `last_sold` — the plant type of the most recently completed sale. Snapshot becomes: `{ n, pt = last_sold, by_pt, earned }`. Report format unchanged.

### Stopping condition

Loop exits when every `id:chapter` key from `SCRIPTS` appears in `milestones`. Add a cycle cap (e.g. 10 000 customer visits) to avoid an infinite loop if something is unreachable.

## What stays the same

- `walk_to` helper — unchanged
- `sell_plant` helper — same mechanics, still triggered by customer arrival
- `check_milestones` — same logic, same snapshot fields
- `sales`, `earned`, `sales_by_pt` counters and their wrapper-table pattern
- Report format and printed table
- Final assert that every chapter was reached

## Open questions

None — both key decisions confirmed (replace file, swap-on-demand slot management).
