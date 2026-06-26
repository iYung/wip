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
    -- Matches real LÖVE behaviour: the separator space is kept as a trailing
    -- character on each non-last wrapped line (no separate separator byte).
    local lines, cur = {}, ""
    for word in text:gmatch("%S+") do
        local candidate = cur == "" and word or (cur .. " " .. word)
        if #candidate * PX > limit and cur ~= "" then
            lines[#lines + 1] = cur .. " "  -- trailing space = real LÖVE
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
    love.graphics.print = function(text)
        -- ignore single-period prints from the period-widening pass
        if text ~= "." then printed[#printed + 1] = text end
    end
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

-- Test: period at end of a middle (non-first, non-last) wrapped line
do
    -- fake font, 8px/char, limit=332 (41.5 chars)
    -- "The very long first sentence that ends." = 39 chars = 312px ≤ 332
    -- Adding " New" = 43 chars = 344px > 332 → wraps after "ends."
    -- line 1: "The very long first sentence that ends."  (39 chars, ends with period)
    -- line 2: "New text here that is also pretty long."  (39 chars, ends with period)
    -- line 3: "Final line."                              (11 chars)
    local TEXT = "The very long first sentence that ends. New text here that is also pretty long. Final line."
    local c = make_customer_for_draw(TEXT, #TEXT)
    local printed = capture_draw(c)
    assert(#printed == 3,
        "three-line text should produce 3 printed lines, got " .. #printed)
    assert(printed[1] == "The very long first sentence that ends.",
        "middle-line period test: line 1 wrong: '" .. tostring(printed[1]) .. "'")
    assert(printed[2] == "New text here that is also pretty long.",
        "middle-line period test: line 2 wrong: '" .. tostring(printed[2]) .. "'")
    assert(printed[3] == "Final line.",
        "middle-line period test: line 3 wrong: '" .. tostring(printed[3]) .. "'")
    print("PASS: dialogue wrap: period at end of middle wrapped line included at full reveal")
end

-- Helper: capture draw calls and return whether arrow_right was drawn
local function capture_arrow_draw(c)
    local arrow_drawn = false
    love.graphics.draw = function(img)
        local A = require("lua/game/assets")
        if img == A.arrow_right then arrow_drawn = true end
    end
    c:draw_bubble()
    love.graphics.draw = function() end
    return arrow_drawn
end

-- Test: arrow shown when text fully revealed and more messages remain
do
    local c = Customer.new(0, 0, 0)
    c.bubble.visible  = true
    c.done_talking    = false
    c.bubble.x        = 0
    c.bubble.y        = 0
    c.messages        = { "First.", "Second." }
    c.msg_index       = 1
    c._full_text      = "First."
    c.reveal_index    = #c._full_text
    local drawn = capture_arrow_draw(c)
    assert(drawn, "arrow should be drawn when text fully revealed and msg_index < #messages")
    print("PASS: dialogue wrap: next-arrow drawn when line complete and more messages remain")
end

-- Test: arrow NOT shown while text is still revealing
do
    local c = Customer.new(0, 0, 0)
    c.bubble.visible  = true
    c.done_talking    = false
    c.bubble.x        = 0
    c.bubble.y        = 0
    c.messages        = { "First.", "Second." }
    c.msg_index       = 1
    c._full_text      = "First."
    c.reveal_index    = 3  -- mid-reveal
    local drawn = capture_arrow_draw(c)
    assert(not drawn, "arrow should NOT be drawn while text is still revealing")
    print("PASS: dialogue wrap: next-arrow hidden while text still revealing")
end

-- Test: arrow shown on last message (player still needs to press to advance)
do
    local c = Customer.new(0, 0, 0)
    c.bubble.visible  = true
    c.done_talking    = false
    c.bubble.x        = 0
    c.bubble.y        = 0
    c.messages        = { "Only line." }
    c.msg_index       = 1
    c._full_text      = "Only line."
    c.reveal_index    = #c._full_text
    local drawn = capture_arrow_draw(c)
    assert(drawn, "arrow should be drawn on the last message so player knows to press")
    print("PASS: dialogue wrap: next-arrow shown on last message")
end

-- Test: arrow shown in talking_after when more after_messages remain
do
    local c = Customer.new(0, 0, 0)
    c.bubble.visible    = true
    c.done_talking      = true
    c.state             = "talking_after"
    c.bubble.x          = 0
    c.bubble.y          = 0
    c.after_messages    = { "Thanks.", "Bye." }
    c.after_msg_index   = 1
    c._full_text        = "Thanks."
    c.reveal_index      = #c._full_text
    local drawn = capture_arrow_draw(c)
    assert(drawn, "arrow should be drawn in talking_after when after_msg_index < #after_messages")
    print("PASS: dialogue wrap: next-arrow drawn in talking_after with more after_messages")
end

-- Test: arrow shown in talking_after on last after_message (player still needs to press to dismiss)
do
    local c = Customer.new(0, 0, 0)
    c.bubble.visible    = true
    c.done_talking      = true
    c.state             = "talking_after"
    c.bubble.x          = 0
    c.bubble.y          = 0
    c.after_messages    = { "Thanks.", "Bye." }
    c.after_msg_index   = 2
    c._full_text        = "Bye."
    c.reveal_index      = #c._full_text
    local drawn = capture_arrow_draw(c)
    assert(drawn, "arrow should be drawn in talking_after on the last after_message so player knows to press")
    print("PASS: dialogue wrap: next-arrow shown on last after_message")
end

print("ALL TESTS PASSED")
