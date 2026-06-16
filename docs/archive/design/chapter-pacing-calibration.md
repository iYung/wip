## Goal

Replace arbitrary trigger counts in `customer_scripts.lua` with data-driven values grounded in what a realistic player can grow and afford. A headless simulation will extend the existing `test_quest_timing.lua` to also track currency at the moment each chapter trigger fires, then compare that against the cost of the plant the chapter customer requests. The output will show, per chapter: when it fires, how much money the player has, and whether they can afford the required plant — giving us a pass/fail affordability signal for every trigger threshold.

## Affected files

- `tests/test_quest_timing.lua` — extend `check_milestones()` to also capture `ctx.gs.currency` at trigger time; add an affordability column to the report table
- `lua/game/data/customer_scripts.lua` — update trigger counts where simulation reveals the customer arrives before the player could afford their requested plant, or where the gap is unrealistically large

## What changes

### `tests/test_quest_timing.lua`

The existing simulation already tracks elapsed time per trigger and outputs a timeline. We add two things:

1. **Currency capture** — in `check_milestones()`, alongside recording `milestones[key] = elapsed`, also record `milestone_currency[key] = ctx.gs.currency`.

2. **Extended report table** — add two new columns to the output:

```
name                  ch   time       clock      currency  plant_cost  afford  trigger
-----------------------------------------------------------------------------------------------
Sir Moneyton          ch1    0.0 s   0m 00 s    $10       $0          OK      Grass >= 0
Sir Moneyton          ch2   32.4 s   0m 32 s    $14       $5          OK      Grass >= 3
Agent Frogsby         ch1   75.1 s   1m 15 s    $22       $5          OK      Cactus >= 2
...
Mayor Bloom           ch2  310.5 s   5m 11 s    $65       $100        WARN    Rose >= 20
...
```

Where:
- `currency` = `ctx.gs.currency` at the moment the trigger fires
- `plant_cost` = `PLANT_DATA[script.plant_type].cost` (cost of the seedling the chapter customer wants)
- `afford` = `OK` if `currency >= plant_cost`, else `WARN`

The "afford" check answers: **at the moment this chapter fires, can the player immediately go buy the required plant?**

Note on same-plant chapters: some chapters request a plant whose type matches the trigger plant (e.g. Mayor Bloom Ch1 wants Rose, triggered by rose×10). The player already has rose plants growing, so `plant_cost` is still shown for completeness but the real check is trivially OK — the plant is already in rotation.

### `lua/game/data/customer_scripts.lua`

After reviewing the extended simulation output:
- Chapters marked `WARN` (player can't afford the required plant when the trigger fires): raise the trigger count so the player has had more time to earn money.
- Chapters where the gap between trigger and affordability is very large (e.g. trigger fires at 30s but player has 10× the required funds): consider lowering the trigger count so the chapter appears sooner, keeping the story moving.

Only `trigger.count` values change. All messages, plant types, character data, and chapter ordering remain untouched.

## What stays the same

- The one-slot, sequential-schedule simulation model in `test_quest_timing.lua`
- The `check_milestones()` optimistic approach (trigger fires as soon as count is met + prior chapters seen)
- The trigger architecture in `store_scene.lua` (stage3_counts-based)
- All chapter content: messages, character names, colors, accessories, plant_type
- `plant_data.lua` costs and sell values (calibrating triggers, not prices)

## Open questions

1. **Same-plant chapters**: When a chapter's requested `plant_type` equals the trigger's `plant_type` (player already grows it), should the affordability check be skipped, or should we check that the player has a stage-3 plant ready to hand over immediately?

2. **Currency at trigger vs. currency after unlocking the next plant**: The simulation spends money when switching plant types (subtracting the seedling cost). At the moment a chapter fires, `ctx.gs.currency` reflects post-purchase state. Should we report pre-purchase or post-purchase balance? Post-purchase is more realistic (the player already spent that money to reach this plant tier).

3. **WARN threshold**: Should `WARN` mean `currency < plant_cost` (can't afford at all), or should we use a cushion like `currency < plant_cost * 1.5` (can afford but with almost nothing left over)?
