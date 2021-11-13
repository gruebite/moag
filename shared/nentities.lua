local nentities = {}
nentities.mt = { __index = nentities }

function nentities.new()
    local self = setmetatable({}, nentities.mt)
    self._lookup = {}
    return self
end

function nentities:add(ent)
    self._lookup[ent.network.id] = ent
end

function nentities:remove(ent)
    if type(ent) == "number" then
        self._lookup[ent] = nil
    else
        self._lookup[ent.network.id] = nil
    end
end

function nentities:get(ent)
    if type(ent) == "number" then
        return self._lookup[ent]
    else
        return self._lookup[ent.network.id]
    end
end

function nentities:iter()
    return pairs(self._lookup)
end

local t = nentities.new()
return t
