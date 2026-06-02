local Sound = require("lua/game/sound")

local SettingsState = {}
SettingsState.__index = SettingsState

function SettingsState.new()
    local self = setmetatable({}, SettingsState)
    self.fullscreen = false
    self.sfx_volume = 100
    self.music_volume = 100
    self.keybinds = {move_up="w", move_down="s", move_left="a", move_right="d", pick_up_down="e", interact="f"}
    return self
end

function SettingsState:set_sfx_volume(v)
    self.sfx_volume = math.max(0, math.min(100, v))
    Sound.set_sfx_volume(self.sfx_volume / 100)
end

function SettingsState:set_music_volume(v)
    self.music_volume = math.max(0, math.min(100, v))
    Sound.set_music_volume(self.music_volume / 100)
end

function SettingsState:toggle_fullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setFullscreen(self.fullscreen)
end

function SettingsState:set_keybind(action, key)
    for other_action, bound_key in pairs(self.keybinds) do
        if other_action ~= action and bound_key == key then
            self.keybinds[other_action] = nil
        end
    end
    self.keybinds[action] = key
end

function SettingsState:key_map()
    local map = {}
    for action, key in pairs(self.keybinds) do
        if key ~= nil then
            map[action] = {key}
        end
    end
    return map
end

return SettingsState
