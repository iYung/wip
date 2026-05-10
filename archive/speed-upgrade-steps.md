# Speed Upgrade Steps

Goal: a purchasable "Speed Boost" upgrade in the shop. Three tiers, each incrementing player speed. Persists on GameState so it survives scene switches.

---

## Tiers

| Tier | Cost | Speed (px/s) |
|------|------|--------------|
| 0 (base) | — | 220 |
| 1 | $15 | 320 |
| 2 | $40 | 480 |
| 3 (max) | $100 | 720 |

---

## Step 1 — Data

- [ ] Add to `config.lua`:
  ```lua
  SPEED_TIERS = {
      { cost = 10, speed = 280 },
      { cost = 20, speed = 340 },
      { cost = 35, speed = 400 },
  }
  ```

---

## Step 2 — GameState

- [ ] Add `speed_level = 0` to `GameState.new()`

---

## Step 3 — Player

- [ ] Replace the hardcoded `SPEED` constant in `Player.new()` with `self.speed = SPEED` (keep `SPEED = 220` as the base default)
- [ ] Replace all uses of `SPEED` in `Player:update()` with `self.speed`

---

## Step 4 — BuyScene Catalogue Entry

- [ ] Add one entry to `CATALOGUE` in `buy_scene.lua`:
  ```lua
  { label = "Speed Boost", kind = "speed_boost", color = {1.0, 0.85, 0.2, 1} }
  ```
  No static `cost` or `description` — these are derived dynamically from `gs.speed_level`.

---

## Step 5 — BuyScene Draw

- [ ] In `BuyScene:draw()`, when `ent.kind == "speed_boost"`, derive display values before the normal draw:
  - If `gs.speed_level >= #SPEED_TIERS`: show description `"Max speed reached."`, cost `"---"`, always dim (can't buy)
  - Otherwise: `tier = SPEED_TIERS[gs.speed_level + 1]`, show description `"Speed: " .. tier.speed .. " px/s"`, cost `tier.cost`
- [ ] `can_buy` check for speed_boost: `gs.speed_level < max AND gs.currency >= tier.cost`

---

## Step 6 — BuyScene Confirm

- [ ] In `BuyScene:_confirm()`, add a branch for `kind == "speed_boost"`:
  - Guard: `gs.speed_level >= #SPEED_TIERS` → return (already maxed)
  - Derive `tier = SPEED_TIERS[gs.speed_level + 1]`
  - Guard: `gs.currency < tier.cost` → return
  - Deduct cost, increment `gs.speed_level`, set `gs.player.speed = tier.speed`
  - Switch back to store scene (same as other purchases)

---

## Step 7 — End-to-End Test

- [ ] Open shop — Speed Boost entry appears in carousel
- [ ] With < $10 — entry is dimmed, F does nothing
- [ ] Buy tier 1 ($10) — player noticeably faster, speed_level = 1
- [ ] Re-open shop — cost now shows $20, description shows 340 px/s
- [ ] Buy tier 2, then tier 3 — each step faster
- [ ] At max — entry shows "Max speed reached.", F does nothing
- [ ] Speed persists after switching to BuyScene and back
