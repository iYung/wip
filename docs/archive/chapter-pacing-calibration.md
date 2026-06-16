## Chapter Pacing Calibration Checklist

- [x] Task A — `tests/test_quest_timing.lua` — Extend to capture player currency at each chapter trigger and add affordability columns to the report; run and confirm output looks correct

- [x] Task B — `lua/game/data/customer_scripts.lua` — Run Task A's extended simulation, read its output, and update `trigger.count` values so no chapter is marked WARN (player can't afford the requested plant when the trigger fires) and no chapter fires unrealistically early — must be done after Task A

---

### Task A detail — `tests/test_quest_timing.lua`

**Goal:** The file already outputs a timeline of when each chapter trigger fires. Extend it to also show `currency`, `plant_cost`, and an `OK`/`WARN` affordability flag per chapter.

**Three changes to make, in order:**

**1. Add a `milestone_currency` table** (alongside the existing `milestones` table, near the top of the file):
```lua
local milestone_currency = {}   -- "id:chapter" -> ctx.gs.currency at trigger time
```

**2. In `check_milestones()`** — after the line `milestones[key] = elapsed`, add:
```lua
milestone_currency[key] = ctx.gs.currency
```

**3. Extend the report section** — in the `sorted` table construction, add `plant_type = s.plant_type` to each entry:
```lua
sorted[#sorted + 1] = {
    key        = s.id .. ":" .. s.chapter,
    name       = s.name,
    chapter    = s.chapter,
    trigger    = s.trigger,
    plant_type = s.plant_type,   -- ADD THIS
    t          = milestones[s.id .. ":" .. s.chapter],
}
```

Then replace the print loop and header with the extended version:
```lua
local PLANT_DATA = require("lua/game/data/plant_data")

print("[quests] quest eligibility timeline  (single slot, optimistic serve):")
print(string.format("  %-20s  %-3s  %8s  %-10s  %-8s  %-10s  %-6s  trigger",
    "name", "ch", "time", "clock", "currency", "plant_cost", "afford"))
print(string.rep("-", 92))
local last_t = 0
for _, q in ipairs(sorted) do
    local t        = q.t or 0
    local currency = milestone_currency[q.key] or 0
    local cost     = PLANT_DATA[q.plant_type].cost
    local afford   = (currency >= cost) and "OK" or "WARN"
    if t > last_t then last_t = t end
    print(string.format("  %-20s  ch%d  %6.1f s  %dm %02.0f s    $%-6d  $%-6d    %-6s  %s >= %d",
        q.name, q.chapter, t,
        math.floor(t / 60), t % 60,
        currency, cost, afford,
        PLANT_NAMES[q.trigger.plant_type], q.trigger.count))
end
print(string.rep("-", 92))
print(string.format("  All quests by:  %6.1f s  (%.1f min)", last_t, last_t / 60))
```

**After making changes:** run `love . --headless tests/test_quest_timing.lua` from `/root/wip` and confirm:
- No Lua errors
- Every row shows currency, cost, and OK/WARN
- At least one WARN is visible (confirming the check is working) OR all are OK (confirming triggers are already well-placed)
- The existing `assert` at the bottom still passes for all chapters

Mark Task A done in this checklist.

---

### Task B detail — `lua/game/data/customer_scripts.lua`

**What to do:**
1. Run the extended simulation: `love . --headless tests/test_quest_timing.lua`
2. Read the output table
3. For each row marked `WARN` (currency < plant_cost at trigger time):
   - Calculate approximately how many more grow cycles of the trigger plant are needed for the player to earn the difference: `extra_cycles = ceil((plant_cost - currency) / sell_value_of_trigger_plant)`
   - Add that many cycles to the trigger count: `new_count = old_count + extra_cycles`
4. For rows where `currency` is dramatically higher than `plant_cost` (more than ~3× the cost) and the chapter fires very late: consider reducing the trigger count to tighten the pacing — a factor of 2× surplus is fine, but 10× means the chapter fires far too late
5. Only change `trigger.count` values — do not change `plant_type`, `id`, `chapter`, messages, or any other field
6. Add a one-line comment above the trigger block citing the simulation: `-- calibrated from tests/test_quest_timing.lua`
7. After changes: run `love . --headless` to confirm all tests still pass
