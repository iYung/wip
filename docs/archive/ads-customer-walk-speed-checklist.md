# Ads Customer Walk Speed Checklist

- [x] Task A — `lua/game/data/cooldown_tiers.lua` — Add `walk_speed = 100` to the tier-1 entry (cost 10).

- [x] Task B — `lua/game/data/cooldown_tiers.lua` — Add `walk_speed = 120` to the tier-2 entry (cost 25).

- [x] Task C — `lua/game/data/cooldown_tiers.lua` — Add `walk_speed = 150` to the tier-3 entry (cost 50).

- [x] Task D — `lua/game/customer.lua` — Remove the module-level `local SPEED = 80` constant (line 14).

- [x] Task E — `lua/game/customer.lua` — In `Customer:show()`, add `self.speed = cfg.walk_speed or 80` to initialize the instance walk speed from the config (with fallback to 80).

- [x] Task F — `lua/game/customer.lua` — In the `walking_in` movement line (currently `self.x = self.x + SPEED * dt`), replace `SPEED` with `self.speed`.

- [x] Task G — `lua/game/customer.lua` — In the `walking_out` movement line (currently `self.x = self.x - SPEED * dt`), replace `SPEED` with `self.speed`.

- [x] Task H — `lua/game/scenes/store_scene.lua` — Add a `customer_walk_speed(gs)` local helper function alongside the existing `spawn_cooldown(gs)` (near line 17): returns `80` when `gs.cooldown_level == 0`, otherwise returns `COOLDOWN_TIERS[gs.cooldown_level].walk_speed`.

- [x] Task I — `lua/game/scenes/store_scene.lua` — At the first `_customer:show(cfg)` call site (~line 234), add `walk_speed = customer_walk_speed(gs)` to the `cfg` table passed in.

- [x] Task J — `lua/game/scenes/store_scene.lua` — At the second `_customer:show(cfg)` call site (~line 239), add `walk_speed = customer_walk_speed(gs)` to the `cfg` table passed in.
