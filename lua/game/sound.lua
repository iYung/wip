local Sound = {}

local _src = {}
local _sfx_volume = 1.0
local _music_volume = 1.0
local _music = nil

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
    if love.filesystem.getInfo("assets/music/background.wav") then
        _music = love.audio.newSource("assets/music/background.wav", "stream")
        _music:setLooping(true)
        _music:setVolume(_music_volume)
        love.audio.play(_music)
    end
end

function Sound.play(name)
    if not love.audio then return end
    local s = _src[name]
    if s then
        local clone = s:clone()
        clone:setVolume(_sfx_volume)
        love.audio.play(clone)
    end
end

function Sound.set_sfx_volume(v)
    _sfx_volume = v
end

function Sound.set_music_volume(v)
    _music_volume = v
    if _music ~= nil then
        _music:setVolume(v)
    end
end

return Sound
