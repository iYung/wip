local Save = {}

local function serialize(val)
    local t = type(val)
    if t == "nil" then
        return "nil"
    elseif t == "number" then
        return tostring(val)
    elseif t == "boolean" then
        return tostring(val)
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(val) do
            local kt = type(k)
            if kt == "number" and math.floor(k) == k then
                parts[#parts + 1] = "[" .. tostring(k) .. "]=" .. serialize(v)
            elseif kt == "string" then
                if k:match("^[%a_][%w_]*$") then
                    parts[#parts + 1] = k .. "=" .. serialize(v)
                else
                    parts[#parts + 1] = "[" .. string.format("%q", k) .. "]=" .. serialize(v)
                end
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "nil"
end

function Save.exists()
    return love.filesystem.getInfo("save.dat") ~= nil
end

function Save.write(data)
    local str = "return " .. serialize(data)
    local ok, err = love.filesystem.write("save.dat", str)
    print("[save] dir=" .. love.filesystem.getSaveDirectory()
          .. " bytes=" .. #str
          .. " ok=" .. tostring(ok)
          .. (err and (" err=" .. tostring(err)) or ""))
end

function Save.read()
    local info = love.filesystem.getInfo("save.dat")
    print("[save] read: exists=" .. tostring(info ~= nil)
          .. " dir=" .. love.filesystem.getSaveDirectory())
    local content, err = love.filesystem.read("save.dat")
    if not content then
        print("[save] read failed: " .. tostring(err))
        return nil
    end
    print("[save] read: " .. #content .. " bytes")
    local loader = loadstring or load
    local ok, result = pcall(function()
        return loader(content)()
    end)
    if not ok then
        print("[save] load() failed: " .. tostring(result))
        return nil
    end
    if result == nil then
        print("[save] load() returned nil (empty or bad content)")
    end
    return result
end

return Save
