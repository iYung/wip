## Goal

Force grafter use for Tulip, Daisy, and Golden Lotus by making each plant's sell price lower than its buy cost. Without the grafter, buying and reselling these plants loses money. The grafter's clone mechanic becomes the only way to profit from them.

Rose (cost=150, sell=50) already works this way. Tulip, Daisy, and Golden Lotus currently all turn a per-plant profit (sell > cost), making the grafter optional.

## Affected files

- `lua/game/data/plant_data.lua` — adjust `cost` and `sell` for plants 4 (Tulip), 5 (Daisy), 6 (Golden Lotus); update description strings to match new sell values
- `tests/test_balance.lua` — add a grafter-loop GPM scenario (Test 3) that simulates never rebuying a plant, to validate that grafter play remains rewarding

## What changes

1. **Plants 4–6 flipped** — `sell < cost` for Tulip, Daisy, and Golden Lotus. Exact values are determined after running the extended balance test. Candidate starting points (to be tuned):
   - Tulip: cost=120, sell=70
   - Daisy: cost=200, sell=100
   - Golden Lotus: cost=1000, sell=600

2. **Balance test: grafter vs buy-loop comparison** — new Test 3 runs the same 60s loop per plant, tracking sales count to compute both grafter/min (gross, no rebuy cost) and buy-loop/min (net after deducting cost × sales). Negative buy-loop confirms grafter is required to profit.

3. **Description strings** — `plant_data.lua` descriptions say "Sells for $X at stage 3." Updated to match new sell values.

4. **Starting currency** — changed from $1000 to $0. With $1000 the player could skip straight to Rose; $0 forces the grass → cactus → rose tutorial progression.

## What stays the same

- Grass (cost=0, sell=3) — free starter plant, no change
- Cactus (cost=9, sell=15) — net-positive without grafter, no change
- Grafter item code and mechanic
- All other upgrade costs (speed, growth, slots, etc.)

## Final values

| Plant        | cost | sell | grafter/min | buy-loop/min |
|--------------|------|------|-------------|--------------|
| Grass        | 0    | 3    | $12         | +$12         |
| Cactus       | 9    | 15   | $45         | +$18         |
| Rose         | 50   | 50   | $100        | $0           |
| Tulip        | 150  | 75   | $150        | −$150        |
| Daisy        | 400  | 250  | $250        | −$150        |
| Golden Lotus | 700  | 400  | $400        | −$300        |

Rose is break-even (cost = sell), acting as the gateway plant where the grafter first becomes useful. Tulip onward are clearly unprofitable to rebuy.
