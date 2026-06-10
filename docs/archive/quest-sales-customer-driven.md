## Quest Sales Customer-Driven Simulation Checklist

- [x] Task A — `tests/test_quest_sales.lua` — rewrite the simulation loop:
  - Remove the hardcoded `schedule` table and the outer schedule `for` loop (including the currency-based unlock sub-loop)
  - Remove `current_pt`; add `local last_sold = 1` and `local available = { [1] = true }` alongside the existing counters
  - Add a `introduce_plants(newly_fired)` helper (or inline logic) that scans any just-fired chapter keys, checks if the chapter's `plant_type` is not yet in `available`, and if so sets `available[pt] = true` and `ctx.gs.unlocked_plants[pt] = true`
  - Replace the schedule loop with a `repeat/until` loop (cap at 10 000 iterations) that:
    1. Fast-forwards until a customer arrives
    2. Reads `ctx.sm.current._customer.plant_type` as `pt`
    3. If `available[pt]`: places `Plant.new(pt)` in slot 4, runs the grow sequence (pick up watering can → walk to slot → wait ready + interact × 2 → walk to watering can → put down → walk to slot → pick up plant), walks to cashier, calls `sell_plant`, sets `last_sold = pt`, calls `check_milestones` then `introduce_plants` on any newly-recorded milestones
    4. If not `available[pt]`: dismiss (press `pick_up_down`, tick once)
    5. Exits when every `id:chapter` key from `SCRIPTS` is in `milestones`
  - Update the milestone snapshot in `check_milestones` to use `pt = last_sold` instead of `pt = current_pt`
  - Keep `walk_to`, `sell_plant`, `check_milestones` signatures and the full report/assert block unchanged
