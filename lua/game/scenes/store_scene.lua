local Scene        = require("lua/core/scene")
local Timer        = require("lua/core/timer")
local Sound        = require("lua/game/sound")
local WateringCan  = require("lua/game/items/watering_can")
local PCStore      = require("lua/game/items/pc_store")
local GarbageBin   = require("lua/game/items/garbage_bin")
local Intercom     = require("lua/game/items/intercom")
local BuyScene     = require("lua/game/scenes/buy_scene")
local PLANT_DATA        = require("lua/game/data/plant_data")
local CUSTOMER_SCRIPTS  = require("lua/game/data/customer_scripts")
local Customer          = require("lua/game/customer")
local config       = require("lua/game/config")
local WallPattern  = require("lua/game/shaders/wall_pattern")
local Sway         = require("lua/game/shaders/sway")
local A            = require("lua/game/assets")
local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")
local WaterDrone     = require("lua/game/water_drone")
local UI             = require("lua/game/ui")

local function spawn_cooldown(gs)
    if gs.cooldown_level == 0 then return 4 end
    return COOLDOWN_TIERS[gs.cooldown_level].cooldown
end

local function customer_walk_speed(gs)
    if gs.cooldown_level == 0 then return 80 end
    return COOLDOWN_TIERS[gs.cooldown_level].walk_speed
end

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

function StoreScene.new(game_state, input, scene_manager, from_save)
    local self          = Scene.new()
    setmetatable(self, StoreScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self._initialized   = false
    self.esc_opens_settings = true
    self._from_save     = from_save or false
    return self
end

function StoreScene:on_enter()
    Sound.stop_music("menu")
    local _bg = {"bg1", "bg2", "bg3", "bg4"}
    local _bg_playing = false
    for _, name in ipairs(_bg) do
        if Sound.is_music_playing(name) then _bg_playing = true; break end
    end
    if not _bg_playing then
        Sound.play_random_music(_bg, 2)
    end

    local gs = self.game_state

    if not self._initialized then
        self._initialized = true
        self:_setup_store()
    end

    if gs.has_drone and not self._drone then
        self._drone = WaterDrone.new(gs.store, 0, gs)
    end
    self.drawer:clear()
    self.drawer:add(gs.store,              0)
    self.drawer:add(self._customer,        1)
    self.drawer:add(self._heat_lamps,      1.5)
    self.drawer:add(self._wall,            2)
    self.drawer:add(self._cashier_floor,   2.5)
    self.drawer:add(self._plant_bubbles,   3)
    if self._drone then
        self.drawer:add(self._drone, 3.5)
    end
    self.drawer:add(gs.player,             4)
    self.drawer:add(self._customer_bubble, 5)

    self.camera.x = gs.player.x
    self.camera.y = CAMERA_Y
end

function StoreScene:_setup_store()
    local gs      = self.game_state
    local store   = gs.store
    local self_ref = self

    self_ref._buy_scene = BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref)
    local buy_scene_factory = function()
        return self_ref._buy_scene
    end

    if not self._from_save then
        store.slots[1].item = WateringCan.new()
        store.slots[2].item = GarbageBin.new()
        store.slots[3].item = PCStore.new(buy_scene_factory)
    end

    local target_x   = -ZONE_WIDTH / 2
    local exit_x     = -(ZONE_WIDTH + 200)
    local customer_y = 500
    self._customer          = Customer.new(target_x, exit_x, customer_y)
    -- Shorten only the very first wait on a brand new game so the opening
    -- customer doesn't leave the player staring at an empty store; it resets
    -- to the normal spawn_cooldown after firing once (see update()).
    local initial_cooldown  = self._from_save and spawn_cooldown(gs) or 0.1
    self._spawn_timer       = Timer.new(initial_cooldown)
    self._active_script_key = nil
    self._active_script     = nil
    self._script_cooldowns  = {}

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

    if self._from_save then
        self:_wire_pc_store()
        self:_wire_intercom()
        self:_wire_drone()
    end
end

function StoreScene:_wire_pc_store()
    local gs    = self.game_state
    local store = gs.store
    local self_ref = self

    local factory = function()
        return self_ref._buy_scene
    end

    for _, slot in ipairs(store.slots) do
        if slot.item and slot.item.name == "Laptop" then
            slot.item.buy_scene_factory = factory
        end
    end
    if gs.player.held_item and gs.player.held_item.name == "Laptop" then
        gs.player.held_item.buy_scene_factory = factory
    end
end

function StoreScene:_wire_intercom()
    local gs = self.game_state
    local getter = function() return self._customer end
    for _, slot in ipairs(gs.store.slots) do
        if slot.item and slot.item.name == "Intercom" then
            slot.item:set_customer_getter(getter)
        end
    end
    if gs.player.held_item and gs.player.held_item.name == "Intercom" then
        gs.player.held_item:set_customer_getter(getter)
    end
end

function StoreScene:_wire_drone()
    local gs = self.game_state
    if gs.has_drone and not self._drone then
        self._drone = WaterDrone.new(gs.store, 0, gs)
    end
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
        self._active_script     = script
        return script
    end

    self._active_script_key = nil
    self._active_script     = nil
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
    if self._drone then
        self._drone:update(dt)
    end

    for _, slot in ipairs(gs.store.slots) do
        slot.highlighted = false
    end
    if gs.player.x >= 0 then
        local active = gs.player:active_slot(gs.store)
        if active then active.highlighted = true end
    end

    if not self._customer:active() then
        local cd = spawn_cooldown(self.game_state)
        if cd == 0 then
            local cfg = self:_next_customer_cfg()
            if cfg then
                cfg.walk_speed = customer_walk_speed(gs)
                self._customer:show(cfg)
            end
        elseif self._spawn_timer:update(dt) then
            local cfg = self:_next_customer_cfg()
            if cfg then
                cfg.walk_speed = customer_walk_speed(gs)
                self._customer:show(cfg)
            end
            self._spawn_timer:reset(cd)
        end
    end

    self.camera:follow(gs.player, CAMERA_LERP)
    self.camera.y = CAMERA_Y

    local half_w      = config.LOGICAL_W / 2
    local world_left  = -ZONE_WIDTH
    local world_right = gs.store:width()
    self.camera.x = math.max(world_left + half_w, math.min(world_right - half_w, self.camera.x))

    if input:pressed("move_up") then
        self:_handle_pick_up()
    elseif input:pressed("move_down") then
        self:_handle_put_down()
    end

    if input:pressed("interact") then
        self:_handle_interact()
    end
end

function StoreScene:_handle_pick_up()
    local player = self.game_state.player
    local store  = self.game_state.store
    local slot   = player:active_slot(store)

    if player.x < 0 then
        if self._customer:arrived() and not (self._active_script and self._active_script.no_dismiss) then
            self._customer:dismiss()
            if self._active_script_key then
                self._script_cooldowns[self._active_script_key] = DISMISS_COOLDOWN_SALES
                self._active_script_key = nil
                self._active_script     = nil
            end
        end
        return
    end

    if player.held_item then
        -- swap: pick up slot item, put held item down
        if slot and slot.item and slot.item.carriable then
            local tmp        = player.held_item
            player.held_item = slot.item
            slot.item        = tmp
            Sound.play("put_down")
        end
    else
        -- pick up from slot
        if slot and slot.item and slot.item.carriable then
            player.held_item = slot.item
            slot.item        = nil
            Sound.play("pick_up")
        end
    end
end

function StoreScene:_handle_put_down()
    local player = self.game_state.player
    local store  = self.game_state.store
    local slot   = player:active_slot(store)

    if player.x < 0 then
        if self._customer:arrived() and not (self._active_script and self._active_script.no_dismiss) then
            self._customer:dismiss()
            if self._active_script_key then
                self._script_cooldowns[self._active_script_key] = DISMISS_COOLDOWN_SALES
                self._active_script_key = nil
                self._active_script     = nil
            end
        end
        return
    end

    if player.held_item then
        if slot and not slot.item then
            -- put down into empty slot
            slot.item        = player.held_item
            player.held_item = nil
            Sound.play("put_down")
        elseif slot and slot.item and slot.item.carriable then
            -- swap: put held item down, pick up slot item
            local tmp        = player.held_item
            player.held_item = slot.item
            slot.item        = tmp
            Sound.play("put_down")
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
            Sound.play("shop_buy")
            if self._active_script_key then
                self.game_state.seen_scripts[self._active_script_key] = true
                self._active_script_key = nil
                self._active_script     = nil
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
                return
            end
            self._customer:advance()
        end
        return
    end

    -- held item + garbage bin → discard
    if player.x >= 0 and player.held_item and player.held_item.sellable ~= false and slot and slot.item and slot.item.is_garbage_bin then
        player.held_item = nil
        Sound.play("put_down")
        return
    end

    local item = player.held_item or (slot and slot.item)
    if item then
        local prev_stage = slot and slot.item and slot.item.stage
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

    local up_key   = (self.input:key_for("move_up")   or "w"):upper()
    local down_key = (self.input:key_for("move_down") or "s"):upper()
    local f_key = (self.input:key_for("interact")     or "space"):upper()

    local slot_label
    if player.x >= 0 then
        slot_label = slot_item and slot_item.name and ("HOVERING " .. slot_item.name:upper())
    elseif self._customer and self._customer:active() then
        local moving = self._customer.state == "walking_in" or self._customer.state == "walking_out"
        if not moving then
            slot_label = "HOVERING " .. self._customer.name:upper()
        end
    end

    local up_label
    local down_label
    if player.x < 0 and self._customer and self._customer:arrived() and not (self._active_script and self._active_script.no_dismiss) then
        up_label = up_key .. "/" .. down_key .. ": DISMISS"
    elseif player.x >= 0 then
        if held and slot_item and slot_item.carriable then
            up_label = up_key .. "/" .. down_key .. ": SWAP WITH " .. slot_item.name:upper()
        elseif not held and slot_item and slot_item.carriable then
            up_label = up_key .. ": PICK UP"
        elseif held and slot and not slot_item then
            down_label = down_key .. ": PUT DOWN"
        end
    end

    local f_label
    if player.x < 0 and self._customer and self._customer.state == "talking_after" then
        if not self._customer:line_complete() then
            f_label = f_key .. ": SKIP"
        else
            f_label = f_key .. ": CONTINUE"
        end
    elseif player.x < 0 and self._customer and self._customer:arrived() then
        if self._customer:on_last_message() then
            if held and held.plant_type == self._customer.plant_type and held.stage == 3 then
                f_label = f_key .. ": SELL TO CUSTOMER ($" .. plant_sell_value(held) .. ")"
            end
        else
            if not self._customer:line_complete() then
                f_label = f_key .. ": SKIP"
            else
                f_label = f_key .. ": NEXT"
            end
        end
    elseif not held and slot_item and slot_item.buy_scene_factory then
        f_label = f_key .. ": OPEN SHOP"
    elseif held and held.name == "Watering Can" and slot_item and slot_item.plant_type and slot_item.ready then
        f_label = f_key .. ": WATER"
    elseif held and held.name == "Grafter" and slot_item and slot_item.stage == 3 then
        f_label = f_key .. ": CLONE"
    elseif held and held.sellable ~= false and slot_item and slot_item.is_garbage_bin then
        f_label = f_key .. ": DISCARD"
    end

    return { slot = slot_label, up = up_label, down = down_label, f = f_label }
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

    gs.store:draw_bg(A)

    gs.store.sway_time = self._sway_time
    self.drawer:draw()
    self.camera:detach()

    UI.draw_currency_bubble(gs.currency, 10, 10, love.graphics.getFont())

    -- context HUD: bottom-left, stacked downward inside box
    local hud    = self:_hud_labels()
    local labels = {}
    if hud.slot then table.insert(labels, hud.slot) end
    if hud.f    then table.insert(labels, hud.f) end
    if hud.up   then table.insert(labels, hud.up) end
    if hud.down then table.insert(labels, hud.down) end

    UI.draw_hud_box(labels, love.graphics.getFont())

    love.graphics.setColor(0, 0, 0, 1)
    local box_h = #labels * 20 + 28
    local y = 720 - 10 - box_h + 14
    for _, label in ipairs(labels) do
        love.graphics.print(label, 10 + 14, y)
        y = y + 20
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return StoreScene
