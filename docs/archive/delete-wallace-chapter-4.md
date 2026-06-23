## Delete Wallace Chapter 4 Checklist

- [x] Task A — `lua/game/data/customer_scripts.lua` — delete the chapter 4 entry (the Golden Lotus / house-fire visit, ~lines 809–829) and fix the comment on the Wallace block to read "3-chapter arc; rose → daisy → daisy"
- [x] Task B — `tests/test_customer_scripts.lua` — remove all four `seen_scripts["wallace:4"] = true` lines (appear in two test setups) and delete the two Wallace ch3 trigger tests that pre-mark ch4 (lines ~636–664 area); keep the ch3 trigger tests themselves intact
- [x] Task C — `tests/test_quest_timing.lua` — remove the `wallace:4` annotation from the Lotus row comment (line ~121); if `wallace:4` is the only reason that row exists, remove the row entirely
