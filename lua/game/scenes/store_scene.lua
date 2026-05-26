local Scene        = require("lua/core/scene")
local Timer        = require("lua/core/timer")
local Sound        = require("lua/game/sound")
local WateringCan  = require("lua/game/items/watering_can")
local PCStore      = require("lua/game/items/pc_store")
local GarbageBin   = require("lua/game/items/garbage_bin")
local BuyScene     = require("lua/game/scenes/buy_scene")
local PLANT_DATA        = require("lua/game/data/plant_data")
local CUSTOMER_SCRIPTS  = require("lua/game/data/customer_scripts")
local Customer          = require("lua/game/customer")
local config       = require("lua/game/config")
local WallPattern  = require("lua/game/shaders/wall_pattern")
local Sway         = require("lua/game/shaders/sway")
local ZONE_WIDTH   = config.ZONE_WIDTH
local U            = config.U

local function plant_sell_value(plant)
    if plant.stage ~= 3 then return 1 end
    local pd = PLANT_DATA[plant.plant_type]
    return pd and pd.sell or 5
end

local CAMERA_Y    = 440  -- fixed world y the camera locks to
local CAMERA_LERP = 0.85 -- smoothing: 0=instant, 1=no movement; 0.85 = smooth lag

local DISMISS_COOLDOWN_SALES = 3  -- scripted customer returns after this many other sales

local StoreScene = setmetatable({}, { __index = Scene })
StoreScene.__index = StoreScene

function StoreScene.new(game_state, input, scene_manager)
    local self          = Scene.new()
    setmetatable(self, StoreScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self._initialized   = false
    self.esc_opens_settings = true
    return self
end

function StoreScene:on_enter()
    local gs = self.game_state

    if not self._initialized then
        self._initialized = true
        self:_setup_store()
    end

    self.drawer:clear()
    self.drawer:add(gs.store,              0)
    self.drawer:add(self._customer,        1)
    self.drawer:add(self._heat_lamps,      1.5)
    self.drawer:add(self._wall,            2)
    self.drawer:add(self._cashier_floor,   2.5)
    self.drawer:add(self._plant_bubbles,   3)
    self.drawer:add(gs.player,             4)
    self.drawer:add(self._customer_bubble, 5)

    self.camera.x = gs.player.x
    self.camera.y = CAMERA_Y
end

function StoreScene:_setup_store()
    local gs      = self.game_state
    local store   = gs.store
    local self_ref = self

    store.slots[1].item = WateringCan.new()
    store.slots[2].item = GarbageBin.new()

    store.slots[3].item = PCStore.new(function()
        local slot = gs.player:active_slot(store)
        return BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref, slot)
    end)

    local target_x   = -ZONE_WIDTH / 2
    local exit_x     = -(ZONE_WIDTH + 200)
    local customer_y = 500
    self._customer          = Customer.new(target_x, exit_x, customer_y)
    self._spawn_timer       = Timer.new(math.random(3, 6))
    self._active_script_key = nil
    self._script_cooldowns  = {}

    local A        = require("lua/game/assets")
    local wall_img = A.cashier_wall
    local slot_img = A.slot

    self._wall = {
        draw = function()
            love.graphics.setColor(1, 1, 1, 1)
            if A.wall_pattern then WallPattern.apply(A.wall_pattern, -ZONE_WIDTH, 0.0, wall_img) end
            love.graphics.draw(wall_img, -ZONE_WIDTH, 0)
            if A.wall_pattern then WallPattern.clear() end
        end
    }

    local customer_ref = self._customer
    self._customer_bubble = {
        draw = function() customer_ref:draw_bubble() end
    }

    local store_ref = gs.store
    self._plant_bubbles = {
        draw = function() store_ref:draw_bubbles() end
    }

    self._sway_time = 0

    self._parallax_layers = {
        { img = A.store_bg_far,  p = 0.05 },
        { img = A.store_bg_mid,  p = 0.20, sway_amplitude = 0.004 },
        { img = A.store_bg_near, p = 0.45, sway_amplitude = 0.007 },
    }

    local floor_y  = 30 * U
    local slot_w   = store_ref.slot_width
    local sx = slot_w / slot_img:getWidth()
    local sy = slot_w / slot_img:getHeight()
    self._cashier_floor = {
        draw = function()
            love.graphics.setColor(1, 1, 1, 1)
            local fx = -ZONE_WIDTH
            while fx < 0 do
                love.graphics.draw(slot_img, fx, floor_y, 0, sx, sy)
                fx = fx + slot_w
            end
        end
    }

    local gs_ref = gs
    self._heat_lamps = {
        draw = function()
            local lvl = gs_ref.growth_level
            if lvl < 1 then return end
            local lamp = A.heat_lamps and A.heat_lamps[lvl]
            if not lamp then return end
            love.graphics.setColor(1, 1, 1, 1)
            local lamp_w = store_ref.slot_width * 2
            local scale  = lamp_w / lamp:getWidth()
            local slots  = store_ref.slots
            local i = 1
            while i + 1 <= #slots do
                love.graphics.draw(lamp, slots[i].x, 80, 0, scale, scale)
                i = i + 2
            end
        end
    }
end

function StoreScene:_next_customer_cfg()
    local gs = self.game_state

    local qualified = {}
    for _, script in ipairs(CUSTOMER_SCRIPTS) do
        local key = script.id .. ":" .. script.chapter
        if not gs.seen_scripts[key] and not self._script_cooldowns[key] then
            local t = script.trigger
            if (gs.stage3_counts[t.plant_type] or 0) >= t.count then
                local prior_ok = true
                for ch = 1, script.chapter - 1 do
                    if not gs.seen_scripts[script.id .. ":" .. ch] then
                        prior_ok = false
                        break
                    end
                end
                if prior_ok then
                    qualified[#qualified + 1] = script
                end
            end
        end
    end

    if #qualified > 0 then
        local script = qualified[math.random(#qualified)]
        self._active_script_key = script.id .. ":" .. script.chapter
        return script
    end

    self._active_script_key = nil
    local keys = {}
    for pt in pairs(gs.unlocked_plants) do
        keys[#keys + 1] = pt
    end
    if #keys == 0 then return nil end
    local pt = keys[math.random(#keys)]
    return {
        plant_type     = pt,
        primary_color   = { math.random(), math.random(), math.random(), 1 },
        secondary_color = { math.random(), math.random(), math.random(), 1 },
    }
end

function StoreScene:on_exit()
    self.drawer:clear()
end

function StoreScene:update(dt)
    local gs    = self.game_state
    local input = self.input

    self._sway_time = self._sway_time + dt

    gs.store:update(dt * gs.growth_mult)
    gs.player:update(dt, input, gs.store)
    self._customer:update(dt)

    for _, slot in ipairs(gs.store.slots) do
        slot.highlighted = false
    end
    if gs.player.x >= 0 then
        local active = gs.player:active_slot(gs.store)
        if active then active.highlighted = true end
    end

    if not self._customer:active() then
        if self._spawn_timer:update(dt) then
            local cfg = self:_next_customer_cfg()
            if cfg then
                self._customer:show(cfg)
            end
            self._spawn_timer:reset(math.random(3, 6))
        end
    end

    self.camera:follow(gs.player, CAMERA_LERP)
    self.camera.y = CAMERA_Y

    local half_w      = 640
    local world_left  = -ZONE_WIDTH
    local world_right = gs.store:width()
    self.camera.x = math.max(world_left + half_w, math.min(world_right - half_w, self.camera.x))

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

    if player.x < 0 then
        if self._customer:arrived() then
            self._customer:dismiss()
            Sound.play("dismiss_customer")
            if self._active_script_key then
                self._script_cooldowns[self._active_script_key] = DISMISS_COOLDOWN_SALES
                self._active_script_key = nil
            end
        elseif self._customer.state == "talking_after" then
            self._customer:dismiss()
        end
        return
    end

    if player.held_item then
        if slot and not slot.item then
            slot.item        = player.held_item
            player.held_item = nil
            Sound.play("put_down")
        end
    else
        if slot and slot.item and slot.item.carriable then
            player.held_item = slot.item
            slot.item        = nil
            Sound.play("pick_up")
        end
    end
end

function StoreScene:_handle_interact()
    local player = self.game_state.player
    local store  = self.game_state.store
    local slot   = player:active_slot(store)

    -- cashier zone: dialog advance or sale
    if player.x < 0 and self._customer.state == "talking_after" then
        self._customer:advance_after()
        return
    end

    if player.x < 0 and self._customer:arrived() then
        local held = player.held_item
        if self._customer:on_last_message() and held and held.plant_type == self._customer.plant_type and held.stage == 3 then
            local value = plant_sell_value(held)
            self.game_state.currency = self.game_state.currency + value
            player.held_item = nil
            self._customer:serve()
            Sound.play("sell_plant")
            if self._active_script_key then
                self.game_state.seen_scripts[self._active_script_key] = true
                self._active_script_key = nil
            end
            for key, count in pairs(self._script_cooldowns) do
                local remaining = count - 1
                if remaining <= 0 then
                    self._script_cooldowns[key] = nil
                else
                    self._script_cooldowns[key] = remaining
                end
            end
        else
            if not self._customer:line_complete() then
                self._customer:skip_reveal()
                Sound.play("dialogue_skip")
                return
            end
            self._customer:advance()
            Sound.play("dialogue_advance")
        end
        return
    end

    -- held item + garbage bin → discard
    if player.held_item and player.held_item.sellable ~= false and slot and slot.item and slot.item.is_garbage_bin then
        player.held_item = nil
        Sound.play("discard_plant")
        return
    end

    local item = player.held_item or (slot and slot.item)
    if item then
        local prev_stage = slot and slot.item and slot.item.stage
        if item.buy_scene_factory then Sound.play("open_shop") end
        item:interact(player, store, self.scene_manager)
        if slot and slot.item and slot.item.stage == 3 and prev_stage == 2 then
            local pt = slot.item.plant_type
            self.game_state.stage3_counts[pt] = (self.game_state.stage3_counts[pt] or 0) + 1
        end
    end
end

function StoreScene:_hud_labels()
    local player    = self.game_state.player
    local store     = self.game_state.store
    local slot      = player:active_slot(store)
    local held      = player.held_item
    local slot_item = slot and slot.item

    local slot_label = player.x >= 0 and slot_item and slot_item.name and ("HOVER: " .. slot_item.name:upper())

    local e_label
    if player.x < 0 and self._customer and self._customer:arrived() then
        e_label = "E: DISMISS"
    elseif player.x >= 0 then
        if held and slot and not slot_item then
            e_label = "E: PUT DOWN"
        elseif not held and slot_item and slot_item.carriable then
            e_label = "E: PICK UP"
        end
    end

    local f_label
    if player.x < 0 and self._customer and self._customer:arrived() then
        if self._customer:on_last_message() then
            if held and held.plant_type == self._customer.plant_type and held.stage == 3 then
                f_label = "F: SELL TO CUSTOMER ($" .. plant_sell_value(held) .. ")"
            end
        else
            if not self._customer:line_complete() then
                f_label = "F: SKIP"
            else
                f_label = "F: NEXT"
            end
        end
    elseif not held and slot_item and slot_item.buy_scene_factory then
        f_label = "F: OPEN SHOP"
    elseif held and held.name == "Watering Can" and slot_item and slot_item.plant_type then
        f_label = "F: WATER"
    elseif held and held.name == "Grafter" and not held.loaded_plant and slot_item and slot_item.stage == 3 then
        f_label = "F: CLONE"
    elseif held and held.sellable ~= false and slot_item and slot_item.is_garbage_bin then
        f_label = "F: DISCARD"
    end

    return { slot = slot_label, e = e_label, f = f_label }
end

function StoreScene:draw()
    local gs = self.game_state
    self.camera:attach()

    local cx      = self.camera.x
    local start_x = -ZONE_WIDTH
    local end_x   = gs.store:width()
    love.graphics.setColor(1, 1, 1, 1)
    for _, layer in ipairs(self._parallax_layers) do
        if layer.img then
            local iw     = layer.img:getWidth()
            local offset = -cx * (1 - layer.p)
            local x      = math.floor((start_x + offset) / iw) * iw - offset
            if layer.sway_amplitude then
                Sway.apply(self._sway_time, layer.sway_amplitude)
            end
            while x < end_x do
                love.graphics.draw(layer.img, x, 0)
                x = x + iw
            end
            if layer.sway_amplitude then
                Sway.clear()
            end
        end
    end

    local A = require("lua/game/assets")
    gs.store:draw_bg(A)

    gs.store.sway_time = self._sway_time
    self.drawer:draw()
    self.camera:detach()

    love.graphics.setColor(1, 1, 1, 0.8)
    local cur_text = "Currency: " .. gs.currency
    love.graphics.print(cur_text, 10, 10)

    -- context HUD: bottom-left, stacked upward (hover at bottom, then f, then e)
    local hud    = self:_hud_labels()
    local labels = {}
    if hud.slot then table.insert(labels, hud.slot) end
    if hud.f    then table.insert(labels, hud.f) end
    if hud.e    then table.insert(labels, hud.e) end

    local y = 700
    for _, label in ipairs(labels) do
        love.graphics.print(label, 10, y)
        y = y - 20
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return StoreScene
