local A = {}

local function img(path)
    return love.graphics.newImage(path)
end

A.player_idle      = img("assets/player_idle.png")
A.player_walk      = img("assets/player_walk.png")
A.player_idle_held = img("assets/player_idle_held.png")
A.player_walk_held = img("assets/player_walk_held.png")

A.customer        = img("assets/customer.png")
A.customer_bubble = img("assets/customer_bubble.png")

A.plant_bubble = img("assets/plant_bubble.png")
for pt = 1, 6 do
    A["plant_" .. pt] = {}
    for stage = 1, 3 do
        A["plant_" .. pt][stage] = img("assets/plant_" .. pt .. "_" .. stage .. ".png")
    end
end

A.watering_can  = img("assets/watering_can.png")
A.grafter_empty  = img("assets/grafter_empty.png")
A.grafter_loaded = img("assets/grafter_loaded.png")
A.sell_bin       = img("assets/sell_bin.png")
A.pc_store       = img("assets/pc_store.png")

A.slot         = img("assets/slot.png")
A.cashier_wall = img("assets/cashier_wall.png")

A.accessories = {}
function A.load_accessory(name)
    if A.accessories[name] ~= nil then return A.accessories[name] end
    local path = "assets/accessories/" .. name .. ".png"
    if love.filesystem.getInfo(path) then
        A.accessories[name] = love.graphics.newImage(path)
    else
        A.accessories[name] = false
    end
    return A.accessories[name]
end

return A
