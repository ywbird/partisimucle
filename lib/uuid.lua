local random = math.random
math.randomseed(os.time())

--- @return string uuid
local function uuid()
  local template = "xxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

return uuid
