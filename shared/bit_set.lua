
local function on(val, idx)
    return bit.bor(val, bit.lshift(1, idx))
end

local function off(val, idx)
    return bit.band(val, bit.bnot(bit.lshift(1, idx)))
end

local function toggle(val, idx)
    return bit.bxor(val, bit.lshift(1, idx))
end

local function has(val, idx)
    return bit.band(val, bit.lshift(1, idx)) ~= 0
end

local function union(val, o)
    return bit.bor(val, o)
end

local function intersect(val, o)
    return bit.band(val, o)
end

local function difference(val, o)
    return bit.band(union(val, o), bit.bnot(intersect(val, o)))
end

local function nbits(val)
    local c = 0
    while val ~= 0 do
        if bit.band(val, 1) ~= 0 then
            c = c + 1
        end
        val = bit.rshift(val, 1)
    end
    return c
end

local function bits(init)
    local bs = 0
    for _, b in ipairs(init) do
        bs = on(bs, b)
    end
    return bs
end

local function to_bits(bs)
    local t = {}
    local i = 0
    while bs ~= 0 do
        if has(bs, 0) then
            t[#t + 1] = i
        end
        i = i + 1
        bs = bit.rshift(bs, 1)
    end
    return t
end

return {
    on = on,
    off = off,
    toggle = toggle,
    has = has,
    union = union,
    intersect = intersect,
    difference = difference,
    bits = bits,
    to_bits = to_bits,
}