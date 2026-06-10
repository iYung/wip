## Quest Sales Tracker Revenue Checklist

- [x] Task A — `tests/test_quest_sales.lua` — add `total_earned` tracking: declare `local total_earned = 0` alongside `sales`/`sales_by_pt`; pass it via a wrapper table into `sell_plant` so it increments by `PLANT_DATA[plant_type].sell` after each completed sale; add `earned = total_earned` to the milestone snapshot in `check_milestones`; add a `$earned` column to the report's format string and header line between `sales` and `selling`.
