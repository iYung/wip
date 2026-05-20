local A = {}

local function img(path)
    return love.graphics.newImage(path)
end

A.player_idle      = img("assets/player_idle.png")
A.player_walk      = img("assets/player_walk.png")
A.player_idle_held = img("assets/player_idle_held.png")
A.player_walk_held = img("assets/player_walk_held.png")

A.buy_bg      = img("assets/buy_bg.png")
A.arrow_left  = img("assets/arrow_left.png")
A.arrow_right = img("assets/arrow_right.png")
A.dot_active   = img("assets/dot_active.png")
A.dot_inactive = img("assets/dot_inactive.png")

A.customer        = img("assets/customer.png")
A.customer_walk   = img("assets/customer_walk.png")
A.customer_bubble = img("assets/customer_bubble.png")
A.heart_bubble    = img("assets/heart_bubble.png")

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
A.garbage_bin    = img("assets/garbage_bin.png")
A.pc_store       = img("assets/pc_store.png")

A.slot         = img("assets/slot.png")
A.cashier_wall = img("assets/cashier_wall.png")

A.store_wall   = img("assets/store_wall.png")
A.store_window = img("assets/store_window.png")

local function try_img(path)
    if love.filesystem.getInfo(path) then return love.graphics.newImage(path) end
end

A.slot_highlight     = img("assets/slot_highlight.png")
A.store_bg_far       = img("assets/shop_bg_far.png")
A.store_bg_mid       = img("assets/shop_bg_mid.png")
A.store_bg_near      = img("assets/shop_bg_near.png")
A.speech_bubble      = img("assets/speech_bubble.png")
A.speech_bubble_tail = img("assets/speech_bubble_tail.png")
A.sneakers           = try_img("assets/sneakers.png")
A.expand_slot        = try_img("assets/expand_slot.png")
A.heat_lamp_icon     = try_img("assets/heat_lamp_icon.png")
A.heat_lamps = {}
for lvl = 1, 3 do
    A.heat_lamps[lvl] = try_img("assets/heat_lamp_" .. lvl .. ".png")
end


A.wall_pattern = try_img("assets/wall_pattern.png")
if A.wall_pattern then A.wall_pattern:setWrap("repeat", "repeat") end

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
