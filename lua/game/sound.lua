local Sound = {}

local _src = {}

local _EVENT_NAMES = {
    "pick_up",
    "put_down",
    "water_plant",
    "plant_ready",
    "clone_success",
    "clone_fail",
    "sell_plant",
    "dismiss_customer",
    "dialogue_skip",
    "dialogue_advance",
    "discard_plant",
    "open_shop",
    "shop_navigate",
    "shop_buy",
    "shop_close",
    "menu_navigate",
    "menu_confirm",
}

function Sound.load()
    if not love.audio then return end
    for _, name in ipairs(_EVENT_NAMES) do
        local path = "assets/sounds/" .. name .. ".wav"
        if love.filesystem.getInfo(path) then
            _src[name] = love.audio.newSource(path, "static")
        end
    end
end

function Sound.play(name)
    if not love.audio then return end
    local s = _src[name]
    if s then
        love.audio.play(s:clone())
    end
end

return Sound
