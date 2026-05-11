local Scene        = require("lua/core/scene")
local WateringCan  = require("lua/game/items/watering_can")
local PCStore      = require("lua/game/items/pc_store")
local GarbageBin   = require("lua/game/items/garbage_bin")
local BuyScene     = require("lua/game/scenes/buy_scene")
local PLANT_DATA        = require("lua/game/data/plant_data")
local CUSTOMER_SCRIPTS  = require("lua/game/data/customer_scripts")
local Customer          = require("lua/game/customer")
local config       = require("lua/game/config")
local ZONE_WIDTH   = config.ZONE_WIDTH
local U            = config.U

local function plant_sell_value(plant)
    if plant.stage ~= 3 then return 1 end
    local pd = PLANT_DATA[plant.plant_type]
    return pd and pd.sell or 5
end

local CAMERA_Y    = 440  -- fixed world y the camera locks to
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
    self.drawer:add(gs.store,              0)
    self.drawer:add(self._customer,        1)
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
    self._customer    = Customer.new(target_x, exit_x, customer_y)
    self._spawn_timer = math.random(3, 6)

    local A        = require("lua/game/assets")
    local wall_img = A.cashier_wall
    local slot_img = A.slot

    self._wall = {
        draw = function()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(wall_img, -ZONE_WIDTH, 0)
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
end

function StoreScene:_next_customer_cfg()
    local gs = self.game_state

    local qualified = {}
    for _, script in ipairs(CUSTOMER_SCRIPTS) do
        local key = script.id .. ":" .. script.chapter
        if not gs.seen_scripts[key] then
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
        gs.seen_scripts[script.id .. ":" .. script.chapter] = true
        return script
    end

    local keys = {}
    for pt in pairs(gs.unlocked_plants) do
        keys[#keys + 1] = pt
    end
    if #keys == 0 then return nil end
    local pt = keys[math.random(#keys)]
    return { plant_type = pt }
end

function StoreScene:on_exit()
    self.drawer:clear()
end

function StoreScene:update(dt)
    local gs    = self.game_state
    local input = self.input

    gs.store:update(dt)
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
        self._spawn_timer = self._spawn_timer - dt
        if self._spawn_timer <= 0 then
            local cfg = self:_next_customer_cfg()
            if cfg then
                self._customer:show(cfg)
            end
            self._spawn_timer = math.random(3, 6)
        end
    end

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

    if player.x < 0 then return end

    -- loaded grafter + empty slot → place clone, grafter stays in hand
    if player.held_item and player.held_item.loaded_plant and slot and not slot.item then
        slot.item = player.held_item.loaded_plant
        player.held_item:unload()
        return
    end

    if player.held_item then
        if slot and not slot.item then
            slot.item        = player.held_item
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

    -- cashier zone: dialog advance or sale
    if player.x < 0 and self._customer:arrived() then
        local held = player.held_item
        if self._customer:on_last_message() and held and held.plant_type == self._customer.plant_type and held.stage == 3 then
            local value = plant_sell_value(held)
            self.game_state.currency = self.game_state.currency + value
            player.held_item = nil
            self._customer:serve()
        else
            self._customer:advance()
        end
        return
    end

    -- held item + garbage bin → discard
    if player.held_item and player.held_item.sellable ~= false and slot and slot.item and slot.item.is_garbage_bin then
        local held = player.held_item
        if held.loaded_plant then
            held:unload()
        else
            player.held_item = nil
        end
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

    local slot_label = player.x >= 0 and slot_item and slot_item.name and ("HOVER: " .. slot_item.name:upper())

    local e_label
    if player.x >= 0 then
        if held and held.loaded_plant and slot and not slot_item then
            e_label = "E: PLACE CLONE"
        elseif held and slot and not slot_item then
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
            f_label = "F: NEXT"
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
    self.camera:attach()

    -- zone background (wall PNG draws on top of this via the drawer)
    love.graphics.setColor(0.10, 0.09, 0.14, 1)
    love.graphics.rectangle("fill", -ZONE_WIDTH, 0, ZONE_WIDTH, 800)

    self.drawer:draw()
    self.camera:detach()

    local gs = self.game_state
    love.graphics.setColor(1, 1, 1, 0.8)
    local cur_text = "Currency: " .. gs.currency
    love.graphics.print(cur_text, 1280 - love.graphics.getFont():getWidth(cur_text) - 10, 10)

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
