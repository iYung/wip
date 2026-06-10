## Quest Sales Tracker Checklist

- [x] Task A — `tests/test_quest_sales.lua` — create the headless test: copy the grow-and-sell simulation loop from `test_quest_timing.lua` (same `schedule`, `walk_to`, `sell_plant`, `check_milestones` helpers), add a `total_sales` counter incremented after each completed cashier sale, record `milestones[key] = total_sales` when each chapter trigger fires, print the sales-pacing report table, and assert every chapter was reached.
