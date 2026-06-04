local Sound = {}

local _src = {}
local _animalese_src = nil
local _sfx_volume = 1.0
local _music_volume = 1.0
local _music_tracks = {}

local _EVENT_NAMES = {
    "pick_up",
    "put_down",
    "water_plant",
    "plant_ready",
    "clone_success",
    "clone_fail",
"shop_navigate",
    "shop_buy",
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
    if love.filesystem.getInfo("assets/sounds/animalese.wav") then
        _animalese_src = love.audio.newSource("assets/sounds/animalese.wav", "static")
    end
    if love.filesystem.getInfo("assets/music/menu.wav") then
        local menu_src = love.audio.newSource("assets/music/menu.wav", "stream")
        menu_src:setLooping(true)
        menu_src:setVolume(_music_volume)
        _music_tracks["menu"] = {
            src = menu_src,
            fade_vol = 1,
            fade_target = 1,
            fade_rate = 0,
            stop_on_done = false,
        }
        menu_src:play()
    end
    if love.filesystem.getInfo("assets/music/background.mp3") then
        local bg_src = love.audio.newSource("assets/music/background.mp3", "stream")
        bg_src:setLooping(true)
        bg_src:setVolume(0)
        _music_tracks["bg"] = {
            src = bg_src,
            fade_vol = 1,
            fade_target = 1,
            fade_rate = 0,
            stop_on_done = false,
        }
        -- bg track starts stopped and silent; do not call play
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

function Sound.play_animalese(pitch)
    if not love.audio then return end
    if _animalese_src then
        local clone = _animalese_src:clone()
        clone:setVolume(_sfx_volume)
        clone:setPitch(pitch)
        love.audio.play(clone)
    end
end

function Sound.set_sfx_volume(v)
    _sfx_volume = v
end

function Sound.set_music_volume(v)
    _music_volume = v
    for _, entry in pairs(_music_tracks) do
        if entry.src:isPlaying() then
            entry.src:setVolume(entry.fade_vol * v)
        end
    end
end

function Sound.update(dt)
    for _, entry in pairs(_music_tracks) do
        if entry.fade_rate ~= 0 then
            entry.fade_vol = entry.fade_vol + entry.fade_rate * dt
            -- clamp to [0, 1]
            if entry.fade_vol < 0 then entry.fade_vol = 0 end
            if entry.fade_vol > 1 then entry.fade_vol = 1 end
            entry.src:setVolume(entry.fade_vol * _music_volume)
            -- check if target reached
            if (entry.fade_rate > 0 and entry.fade_vol >= entry.fade_target) or
               (entry.fade_rate < 0 and entry.fade_vol <= entry.fade_target) then
                entry.fade_vol = entry.fade_target
                entry.src:setVolume(entry.fade_vol * _music_volume)
                entry.fade_rate = 0
                if entry.stop_on_done then
                    entry.src:stop()
                    entry.stop_on_done = false
                end
            end
        end
    end
end

function Sound.play_music(name)
    local entry = _music_tracks[name]
    if entry then
        entry.fade_vol = 1
        entry.fade_target = 1
        entry.fade_rate = 0
        entry.stop_on_done = false
        entry.src:setVolume(_music_volume)
        entry.src:play()
    end
end

function Sound.fade_music(name, target_vol, duration)
    local entry = _music_tracks[name]
    if entry then
        if target_vol > 0 and not entry.src:isPlaying() then
            entry.fade_vol = 0
            entry.src:setVolume(0)
            entry.src:play()
        end
        entry.fade_target = target_vol
        entry.fade_rate = (target_vol - entry.fade_vol) / duration
        entry.stop_on_done = (target_vol == 0)
    end
end

function Sound.stop_music(name)
    local entry = _music_tracks[name]
    if entry then
        entry.src:stop()
        entry.fade_vol = 1
        entry.fade_target = 1
        entry.fade_rate = 0
        entry.stop_on_done = false
    end
end

function Sound.is_music_playing(name)
    local entry = _music_tracks[name]
    if entry == nil then return false end
    return entry.src:isPlaying()
end

return Sound
