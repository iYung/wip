local Scene        = require("lua/core/scene")
local WateringCan  = require("lua/game/items/watering_can")
local PCStore      = require("lua/game/items/pc_store")
local BuyScene     = require("lua/game/scenes/buy_scene")

local CAMERA_Y    = 500  -- fixed world y the camera locks to
local CAMERA_LERP = 0.85 -- smoothing: 0=instant, 1=no movement; 0.85 = smooth lag

local StoreScene = setmetatable({}, { __index = Scene })
StoreScene.__index = StoreScene

function StoreScene.new(game_state, input, scene_manager)
    local self          = Scene.new()
    setmetatable(self, StoreScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self._initialized   = false
    return self
end

function StoreScene:on_enter()
    local gs = self.game_state

    if not self._initialized then
        self._initialized = true
        self:_setup_store()
    end

    self.drawer:clear()
    self.drawer:add(gs.store,  0)
    self.drawer:add(gs.player, 2)

    self.camera.x = gs.player.x
    self.camera.y = CAMERA_Y
end

function StoreScene:_setup_store()
    local gs      = self.game_state
    local store   = gs.store
    local self_ref = self

    store.slots[1].item = WateringCan.new()

    store.slots[3].item = PCStore.new(function()
        local slot = gs.player:active_slot(store)
        return BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref, slot)
    end)
end

function StoreScene:on_exit()
    self.drawer:clear()
end

function StoreScene:update(dt)
    local gs    = self.game_state
    local input = self.input

    gs.store:update(dt)
    gs.player:update(dt, input, gs.store)

    self.camera:follow(gs.player, CAMERA_LERP)
    self.camera.y = CAMERA_Y

    if input:pressed("pick_up_down") then
        self:_handle_pick_up_down()
    end

    if input:pressed("interact") then
        self:_handle_interact()
    end
end

function StoreScene:_handle_pick_up_down()
    local player = self.game_state.player
    local store  = self.game_state.store
    local slot   = player:active_slot(store)

    if player.held_item then
        if slot and not slot.item then
            slot.item       = player.held_item
            player.held_item = nil
        end
    else
        if slot and slot.item and slot.item.carriable then
            player.held_item = slot.item
            slot.item        = nil
        end
    end
end

function StoreScene:_handle_interact()
    local player = self.game_state.player
    local store  = self.game_state.store
    local slot   = player:active_slot(store)
    local item   = player.held_item or (slot and slot.item)

    if item then
        item:interact(player, store, self.scene_manager)
    end
end

function StoreScene:draw()
    self.camera:attach()
    self.drawer:draw()
    self.camera:detach()

    -- HUD: show active slot index (screen space)
    local gs   = self.game_state
    local slot = gs.player:active_slot(gs.store)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Slot: " .. (slot and slot.index or "?"), 10, 10)
    love.graphics.print("Move: A/D   Pick Up: E   Interact: F", 10, 30)
    love.graphics.setColor(1, 1, 1, 1)
end

return StoreScene
