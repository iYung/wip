# Checklist: Fix Player Speed Not Applied on Load

- [x] **1. Require SPEED_TIERS in game_state.lua**
  - File: `lua/game/game_state.lua`
  - Add `local SPEED_TIERS = require("lua/game/data/speed_tiers")` near the top with the other requires

- [x] **2. Apply speed tier to player after load**
  - File: `lua/game/game_state.lua`
  - In `GameState.from_save()`, after line 123 (`self.player.held_item = ...`), add:
    ```lua
    if self.speed_level > 0 then
        local tier = SPEED_TIERS[self.speed_level]
        self.player.speed = tier.speed
        self.player:set_speed_color(tier.color)
    end
    ```
