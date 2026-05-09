# Plant Types Steps

Goal: add plant types 2–6. Each type has its own cooldowns, stage colors, and a name. The shop lets the player choose which type to buy.

---

## What Already Exists

- `Plant.new(plant_type)` already accepts a type argument
- `PLANT_COOLDOWNS[plant_type][stage]` drives the cooldown per stage
- Stage colors are currently shared across all types (`STAGE_COLORS` in `plant.lua`)
- Only type 1 is defined in `plant_cooldowns.lua`

---

## Decisions Made

- Names: Fern, Cactus, Rose, Sunflower, Lavender, Golden Lotus (endgame)
- Cooldowns: type 1 = slowest (10s/15s), type 6 = fastest (2s/3s)
- Colors: full 3-stage palette per type in `plant_data.lua`
- Sell value scales with type; cooldowns and colors merged into `plant_data.lua` (no separate `plant_cooldowns.lua`)
- Shop presents each plant type as its own catalogue entry (carousel cycles through all 9 items)

---

## Step 1 — Plant Data

- [x] Give each type a name — added to `lua/game/data/plant_data.lua`
- [x] Add a buy cost per type to `plant_data.lua` (replaces the flat `PLANT_COST` for plants)
- [x] Add cooldowns for types 2–6 in `plant_data.lua` (merged from `plant_cooldowns.lua`, now deleted)
- [x] Add per-type stage color palettes in `plant_data.lua`

---

## Step 2 — Plant.new Uses Per-Type Colors

- [x] In `Plant.new(plant_type)`, look up colors from `PLANT_DATA[plant_type].colors`
- [x] Same for cooldowns — `PLANT_DATA[plant_type].cooldowns[stage]`

---

## Step 3 — Add Plant Types to Shop Catalogue

- [x] `CATALOGUE` in `buy_scene.lua` auto-builds 6 plant entries from `plant_data`, followed by Watering Can, Grafter, Expand Slot
- [x] Flat `PLANT_COST` and `SELL_VALUE` removed from `config.lua`

---

## Step 4 — Sell Value Per Type

- [x] `plant_sell_value(plant)` in `store_scene.lua` looks up `PLANT_DATA[plant_type].sell` at stage 3, returns 1 otherwise
- [x] Works for both directly held plants and plants loaded inside the grafter

---

## Step 5 — End-to-End Test

- [x] Buy each plant type from the shop — correct name shown, correct cost deducted
- [x] Grow each type through stages — correct cooldowns, correct colors per stage
- [x] Sell each type at stage 3 — correct currency awarded
- [x] Graft each type — clone inherits correct plant_type
