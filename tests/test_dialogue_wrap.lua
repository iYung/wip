math.randomseed(42)
require("lua/headless/stubs")
local Customer = require("lua/game/customer")

-- Fake font: wraps at word boundaries using 8px per character.
-- MAX_BOX_W=360, PAD=14 → wrap limit = 360-28 = 332px.
-- "Hello world this is a long message that" = 39 chars = 312px ≤ 332 → line 1
-- "wraps" would make 45 chars = 360px > 332 → wraps to line 2
local PX = 8
local fake_font = {}
fake_font.getHeight = function() return 16 end
fake_font.getWidth  = function(_, s) return #s * PX end
fake_font.getWrap   = function(_, text, limit)
    local lines, cur = {}, ""
    for word in text:gmatch("%S+") do
        local candidate = cur == "" and word or (cur .. " " .. word)
        if #candidate * PX > limit and cur ~= "" then
            lines[#lines + 1] = cur
            cur = word
        else
            cur = candidate
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return (#lines > 0 and #lines[1] or 0) * PX, lines
end

love.graphics.getFont = function() return fake_font end

local function make_customer_for_draw(full_text, reveal_index)
    local c = Customer.new(0, 0, 0)
    c.bubble.visible = true
    c.done_talking   = false
    c._full_text     = full_text
    c.reveal_index   = reveal_index
    c.bubble.x       = 0
    c.bubble.y       = 0
    return c
end

local function capture_draw(c)
    local printed = {}
    love.graphics.print = function(text) printed[#printed + 1] = text end
    c:draw_bubble()
    love.graphics.print = function() end
    return printed
end

local FULL_TEXT = "Hello world this is a long message that wraps"
-- Line 1 of full-text wrap: "Hello world this is a long message that" (39 chars)
-- Line 2 of full-text wrap: "wraps" (5 chars)

-- Test: mid-word reveal at wrap boundary keeps word on line 2, not line 1
do
    -- reveal_index = 41 → "Hello world this is a long message that w"
    -- "w" is the start of "wraps" which belongs on line 2
    local c = make_customer_for_draw(FULL_TEXT, 41)
    local printed = capture_draw(c)
    assert(#printed == 2,
        "mid-word reveal should produce 2 printed lines, got " .. #printed)
    assert(printed[1] == "Hello world this is a long message that",
        "line 1 should be the full first pre-wrapped line, got '" .. tostring(printed[1]) .. "'")
    assert(printed[2] == "w",
        "partial word should appear at the start of line 2, got '" .. tostring(printed[2]) .. "'")
    print("PASS: dialogue wrap: mid-word reveal keeps partial word on its correct line")
end

-- Test: reveal exactly at end of line 1 shows only line 1
do
    -- reveal_index = 39 → "Hello world this is a long message that"
    local c = make_customer_for_draw(FULL_TEXT, 39)
    local printed = capture_draw(c)
    assert(#printed == 1,
        "reveal at end of line 1 should produce 1 printed line, got " .. #printed)
    assert(printed[1] == "Hello world this is a long message that",
        "line 1 should be complete first line, got '" .. tostring(printed[1]) .. "'")
    print("PASS: dialogue wrap: reveal at line 1 end shows only line 1")
end

-- Test: full reveal shows both lines correctly
do
    local c = make_customer_for_draw(FULL_TEXT, #FULL_TEXT)
    local printed = capture_draw(c)
    assert(#printed == 2,
        "full reveal should produce 2 printed lines, got " .. #printed)
    assert(printed[1] == "Hello world this is a long message that",
        "full reveal line 1 wrong: '" .. tostring(printed[1]) .. "'")
    assert(printed[2] == "wraps",
        "full reveal line 2 wrong: '" .. tostring(printed[2]) .. "'")
    print("PASS: dialogue wrap: full reveal shows all pre-wrapped lines")
end

-- Test: reveal in the middle of line 1 shows only partial line 1
do
    -- reveal_index = 5 → "Hello"
    local c = make_customer_for_draw(FULL_TEXT, 5)
    local printed = capture_draw(c)
    assert(#printed == 1,
        "partial line 1 reveal should produce 1 printed line, got " .. #printed)
    assert(printed[1] == "Hello",
        "partial reveal should show first 5 chars, got '" .. tostring(printed[1]) .. "'")
    print("PASS: dialogue wrap: partial line 1 reveal shows only revealed chars")
end

-- Test: reveal_index = 0 prints nothing
do
    local c = make_customer_for_draw(FULL_TEXT, 0)
    local printed = capture_draw(c)
    assert(#printed == 0,
        "reveal_index=0 should print nothing, got " .. #printed)
    print("PASS: dialogue wrap: reveal_index=0 prints nothing")
end

-- Test: period at end of last line is included at full reveal
-- Regression for canvas nearest-neighbour aliasing bug: the period was the
-- most commonly "missing" character because its glyph is only ~2 px wide.
-- The rendering code must include it in rendered_lines even at the very last
-- reveal step.
do
    local TEXT = "Hello world this is a long sentence."
    -- At 8px/char the whole string = 36*8 = 288px ≤ 332 → single line
    local c = make_customer_for_draw(TEXT, #TEXT)
    local printed = capture_draw(c)
    assert(#printed == 1,
        "single-line period text should produce 1 line, got " .. #printed)
    assert(printed[1] == TEXT,
        "full reveal of period-terminated line must include the period, got '" .. tostring(printed[1]) .. "'")
    print("PASS: dialogue wrap: period at end of last line included at full reveal")
end

-- Test: period at end of wrapped line 2 included at full reveal
do
    local TEXT = "Hello world this is a long message that wraps here."
    -- line 1: "Hello world this is a long message that" (39 chars = 312px)
    -- "wraps" would push to 45 chars = 360px > 332 → wraps
    -- line 2: "wraps here." (11 chars)
    local c = make_customer_for_draw(TEXT, #TEXT)
    local printed = capture_draw(c)
    assert(#printed == 2,
        "two-line period text should produce 2 lines, got " .. #printed)
    assert(printed[2] == "wraps here.",
        "last line at full reveal must end with period, got '" .. tostring(printed[2]) .. "'")
    print("PASS: dialogue wrap: period at end of wrapped line 2 included at full reveal")
end

print("ALL TESTS PASSED")
