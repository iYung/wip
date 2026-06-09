local A = {}

local function img(path)
    return love.graphics.newImage(path)
end

A.player_idle      = img("assets/images/player_idle.png")
A.player_walk      = img("assets/images/player_walk.png")
A.player_idle_held = img("assets/images/player_idle_held.png")
A.player_walk_held = img("assets/images/player_walk_held.png")

A.buy_bg      = img("assets/images/buy_bg.png")
A.arrow_left  = img("assets/images/arrow_left.png")
A.arrow_right = img("assets/images/arrow_right.png")
A.dot_active   = img("assets/images/dot_active.png")
A.dot_inactive = img("assets/images/dot_inactive.png")

A.customer        = img("assets/images/customer.png")
A.customer_walk   = img("assets/images/customer_walk.png")
A.customer_bubble = img("assets/images/customer_bubble.png")
A.heart_bubble    = img("assets/images/heart_bubble.png")

A.plant_bubble = img("assets/images/plant_bubble.png")
for pt = 1, 6 do
    A["plant_" .. pt] = {}
    for stage = 1, 3 do
        A["plant_" .. pt][stage] = img("assets/images/plant_" .. pt .. "_" .. stage .. ".png")
    end
end

A.watering_can  = img("assets/images/watering_can.png")
A.grafter_empty  = img("assets/images/grafter_empty.png")
A.garbage_bin    = img("assets/images/garbage_bin.png")
A.pc_store       = img("assets/images/pc_store.png")
A.intercom = img("assets/images/intercom.png")

A.slot         = img("assets/images/slot.png")
A.cashier_wall = img("assets/images/cashier_wall.png")

A.store_wall   = img("assets/images/store_wall.png")
A.store_window = img("assets/images/store_window.png")

local function try_img(path)
    if love.filesystem.getInfo(path) then return love.graphics.newImage(path) end
end

A.slot_highlight     = img("assets/images/slot_highlight.png")
A.store_bg_far       = img("assets/images/shop_bg_far.png")
A.store_bg_mid       = img("assets/images/shop_bg_mid.png")
A.store_bg_near      = img("assets/images/shop_bg_near.png")
A.speech_bubble      = img("assets/images/speech_bubble.png")
A.speech_bubble_tail = img("assets/images/speech_bubble_tail.png")
A.water_drone             = try_img("assets/images/water_drone.png")
A.water_drone2            = try_img("assets/images/water_drone2.png")
A.sneakers                = try_img("assets/images/sneakers.png")
A.expand_slot             = try_img("assets/images/expand_slot.png")
A.heat_lamp_icon          = try_img("assets/images/heat_lamp_icon.png")
A.grafter_no_space_bubble = try_img("assets/images/grafter_no_space_bubble.png")
A.heat_lamps = {}
for lvl = 1, 3 do
    A.heat_lamps[lvl] = try_img("assets/images/heat_lamp_" .. lvl .. ".png")
end

A.ads = {}
for lvl = 1, 3 do
    A.ads[lvl] = try_img("assets/images/ads_" .. lvl .. ".png")
end

A.coin = img("assets/images/coin.png")

A.wall_pattern = try_img("assets/images/wall_pattern.png")
if A.wall_pattern then A.wall_pattern:setWrap("repeat", "repeat") end

A.accessories = {}
function A.load_accessory(name)
    if A.accessories[name] ~= nil then return A.accessories[name] end
    local path = "assets/images/" .. name .. ".png"
    if love.filesystem.getInfo(path) then
        A.accessories[name] = love.graphics.newImage(path)
    else
        A.accessories[name] = false
    end
    return A.accessories[name]
end

return A
