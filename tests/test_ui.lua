package.loaded["lua/game/ui"] = nil
local UI = require("lua/game/ui")

local function make_font(width)
    return { getWidth = function(self, s) return width end }
end

-- draw_hud_box with empty labels does nothing
do
    UI.draw_hud_box({}, make_font(100))
    print("PASS: ui: draw_hud_box with empty labels does nothing")
end

-- draw_hud_box with one label runs without error
do
    UI.draw_hud_box({"E: PICK UP"}, make_font(80))
    print("PASS: ui: draw_hud_box with one label runs without error")
end

-- draw_hud_box with three labels runs without error
do
    UI.draw_hud_box({"E: PUT DOWN", "F: WATER", "HOVER: GRASS"}, make_font(120))
    print("PASS: ui: draw_hud_box with three labels runs without error")
end

-- draw_hud_box calls love.graphics.draw when labels are present
do
    local draw_calls = 0
    local orig_draw  = love.graphics.draw
    love.graphics.draw = function(...) draw_calls = draw_calls + 1 end

    UI.draw_hud_box({"E: PICK UP"}, make_font(80))
    assert(draw_calls > 0, "expected draw_hud_box to call love.graphics.draw, got " .. draw_calls)

    love.graphics.draw = orig_draw
    print("PASS: ui: draw_hud_box calls love.graphics.draw when labels present")
end

-- draw_hud_box skips love.graphics.draw entirely for empty labels
do
    local draw_calls = 0
    local orig_draw  = love.graphics.draw
    love.graphics.draw = function(...) draw_calls = draw_calls + 1 end

    UI.draw_hud_box({}, make_font(80))
    assert(draw_calls == 0, "expected no draw calls for empty labels, got " .. draw_calls)

    love.graphics.draw = orig_draw
    print("PASS: ui: draw_hud_box skips draw for empty labels")
end

-- draw9 is exported and callable with a stub image
do
    local stub_img = { getDimensions = function() return 32, 32 end }
    UI.draw9(stub_img, 0, 0, 64, 64, { top = 8, right = 8, bottom = 8, left = 8 })
    print("PASS: ui: draw9 runs without error with stub image")
end

-- draw9 issues exactly 9 draw calls (one per 9-slice tile)
do
    local draw_calls = 0
    local orig_draw  = love.graphics.draw
    love.graphics.draw = function(...) draw_calls = draw_calls + 1 end

    local stub_img = { getDimensions = function() return 32, 32 end }
    UI.draw9(stub_img, 10, 10, 100, 60, { top = 8, right = 8, bottom = 8, left = 8 })
    assert(draw_calls == 9, "expected 9 draw calls from draw9, got " .. draw_calls)

    love.graphics.draw = orig_draw
    print("PASS: ui: draw9 issues exactly 9 draw calls")
end

print("ALL TESTS PASSED")
