local Sound = {}

local _src = {}
local _animalese_src = nil
local _animalese_last_t = 0
local _sfx_volume = 1.0
local _music_volume = 1.0
local _music_tracks = {}

function Sound.load(manifest)
    if not love.audio then return end
    for _, name in ipairs(manifest.sfx) do
        local path = manifest.sfx_dir .. name .. ".wav"
        if love.filesystem.getInfo(path) then
            _src[name] = love.audio.newSource(path, "static")
        end
    end
    if love.filesystem.getInfo(manifest.animalese) then
        _animalese_src = love.audio.newSource(manifest.animalese, "static")
    end
    for name, track in pairs(manifest.music) do
        if love.filesystem.getInfo(track.path) then
            local autoplay = track.autoplay or false
            local src = love.audio.newSource(track.path, "stream")
            src:setLooping(true)
            src:setVolume(autoplay and _music_volume or 0)
            _music_tracks[name] = {
                src            = src,
                fade_vol       = 1,
                fade_target    = 1,
                fade_rate      = 0,
                stop_on_done   = false,
                playing_intent = autoplay,
            }
            if autoplay then
                src:play()
            end
        end
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
    if love.timer and love.timer.getTime() - _animalese_last_t < 0.05 then return end
    if _animalese_src then
        _animalese_last_t = love.timer and love.timer.getTime() or 0
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
                    entry.playing_intent = false
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
        entry.playing_intent = true
    end
end

function Sound.fade_music(name, target_vol, duration)
    local entry = _music_tracks[name]
    if entry then
        if target_vol > 0 and not entry.src:isPlaying() then
            entry.fade_vol = 0
            entry.src:setVolume(0)
            entry.src:play()
            entry.playing_intent = true
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
        entry.playing_intent = false
        entry.fade_vol = 1
        entry.fade_target = 1
        entry.fade_rate = 0
        entry.stop_on_done = false
    end
end

function Sound.play_random_music(names, fade_duration)
    -- Filter to only names that exist in _music_tracks
    local valid = {}
    for _, name in ipairs(names) do
        if _music_tracks[name] then
            valid[#valid + 1] = name
        end
    end
    if #valid == 0 then return end

    -- Stop any of the valid tracks that are currently playing
    for _, name in ipairs(valid) do
        local entry = _music_tracks[name]
        if entry.src:isPlaying() then
            entry.src:stop()
            entry.playing_intent = false
            entry.fade_vol = 1
            entry.fade_target = 1
            entry.fade_rate = 0
            entry.stop_on_done = false
        end
    end

    -- Pick one at random and fade it in
    local picked = valid[math.random(#valid)]
    Sound.fade_music(picked, 1, fade_duration)
end

function Sound.is_music_playing(name)
    local entry = _music_tracks[name]
    if entry == nil then return false end
    return entry.src:isPlaying()
end

function Sound.on_focus(focused)
    if not love.audio then return end
    if focused then
        for _, entry in pairs(_music_tracks) do
            if entry.playing_intent == true and entry.src:isPlaying() == false then
                entry.src:setVolume(entry.fade_vol * _music_volume)
                entry.src:play()
            end
        end
    end
end

return Sound
