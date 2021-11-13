local Line = {}
Line.__index = Line

function Line.new(x1, y1, x2, y2)
    local self = setmetatable({}, Line)

    x1 = math.floor(x1)
    y1 = math.floor(y1)
    x2 = math.floor(x2)
    y2 = math.floor(y2)
    local dx = math.abs(x2 - x1)
    local sx = x1 < x2 and 1 or -1
    local dy = math.abs(y2 - y1)
    local sy = y1 < y2 and 1 or -1
    local err, e2
    if dx > dy then
        err = math.floor(dx / 2)
    else
        err = math.ceil(-dy / 2)
    end

    self._path = {}

    while true do
        table.insert(self._path, { x = x1, y = y1 })

        if x1 == x2 and y1 == y2 then
            break
        end

        e2 = err
        if e2 > -dx then
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dy then
            err = err + dx
            y1 = y1 + sy
        end
    end

    return self
end

function Line:get_length()
    return #self._path
end

function Line:walk()
    local i = 0
    local n = table.getn(self._path)
    return function()
        i = i + 1
        if i <= n then
            return self._path[i].x, self._path[i].y
        end
    end
end

function Line:walk_reverse()
    local i = table.getn(self._path) + 1
    local n = 1
    return function()
        i = i - 1
        if i >= n then
            return self._path[i].x, self._path[i].y
        end
    end
end

return Line


