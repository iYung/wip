## Grafter Flicker Fix Checklist

- [x] Task A — `lua/game/items/grafter.lua` — after `best_slot.item = Plant.new(plant.plant_type)`, call `best_slot:update(0)` to position the new plant's sprite before the frame draws
