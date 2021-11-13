local Set = {}
Set.__index = Set

function Set.new(arr)
    local self = setmetatable({}, Set)
    self:from_array(arr)
    return self
end

function Set:from_array(arr)
    self._elems = {}
    for _, v in ipairs(arr or {}) do
        self._elems[v] = true
    end
end

function Set:to_array()
    local t = {}
    for k, _ in pairs(self._elems) do
        table.insert(t, k)
    end
    return t
end

function Set:get_size()
    return #self:to_array()
end

function Set:union(other)
    local s = Set.new()
    for k, _ in pairs(self._elems) do
        s._elems[k] = true
    end
    for k, _ in pairs(other) do
        s._elems[k] = true
    end
    return s
end

function Set:difference(other)
    local s = Set.new()
    for k, _ in pairs(self._elems) do
        s._elems[k] = other._elems[k] and false or true
    end
    return s
end

function Set:intersect(other)
    local s = Set.new()
    for k, _ in pairs(self._elems) do
        s._elems[k] = other._elems[k]
    end
    return s
end

function Set:iter()
    local i = nil
    return function()
        i, _ = next(self._elems, i)
        return i
    end
end

if _G.RUN_TESTS then
    local s = Set.new({ "hi", "there" })
    for i in s:iter() do
        print(i)
    end
end

return Set
