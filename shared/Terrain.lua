--[[
Terrain is an object that both the client and server uses. It requires a 
delegate to pass functions to. This is so the client can use a texture to
efficiently store land data.
--]]

local Vec2 = require("shared.Vec2")

local Terrain = {}
Terrain.__index = Terrain

Terrain.OOB_DOWN = -3
Terrain.OOB_UP = -2
Terrain.OOB_SIDES = -1
Terrain.AIR = 0
Terrain.DIRT = 1

function Terrain.new(delegate)
    local self = setmetatable({}, Terrain)
    self.delegate = assert(delegate, "missing delegate parameter")
    return self
end

function Terrain:get_width()
    return self.delegate:get_width()
end

function Terrain:get_height()
    return self.delegate:get_height()
end

function Terrain:in_bounds(pos)
    return 
        pos.x >= 1 and pos.y >= 1 and
        pos.x <= self:get_width() and pos.y <= self:get_height()
end

function Terrain:get_at(pos)
    pos = pos:as_ints()
    if pos.x < 1 or pos.x > self:get_width() then
        return Terrain.OOB_SIDES
    elseif pos.y < 1 then
        return Terrain.OOB_UP
    elseif pos.y > self:get_height() then
        return Terrain.OOB_DOWN
    end
    return self.delegate:get_at(pos)
end

function Terrain:set_at(pos, to)
    if not self:in_bounds(pos) then
        return
    end
    self.delegate:set_at(pos:as_ints(), to)
end

function Terrain:is_solid(pos)
    return self:get_at(pos) == Terrain.DIRT
end

function Terrain:set_circle(cen, rad, to)
    for x = cen.x - rad, cen.x + rad do
        for y = cen.y - rad, cen.y + rad do
            local v = Vec2.new(x, y)
            if v:distance2(cen) < rad * rad then
                self:set_at(v, to)
            end
        end
    end
end

function Terrain:set_rect(tl, br, to)
    for x = tl.x, br.x do
        for y = tl.y, br.y do
            self:set_at(Vec2.new(x, y), to)
        end
    end
end

-- SPECIAL

function Terrain:collapse(pos, rad)
    local x = pos.x
    local y = pos.y

    for ix = -rad, rad do
        local height = 0
        for iy = -rad, rad do
            if (ix * ix) + (iy * iy) < (rad * rad) and self:is_solid(Vec2.new(x + ix, y + iy)) then
                height = height + 1
            end
        end
        for iy = rad, -rad, -1 do
            if (ix * ix) + (iy * iy) < (rad * rad) then
                if height > 0 then
                    self:set_at(Vec2.new(x + ix, y + iy), Terrain.DIRT)
                else
                    self:set_at(Vec2.new(x + ix, y + iy), Terrain.AIR)
                end
                height = height - 1
            end
        end
    end
end

function Terrain:pour_liquid(pos, amount)
    pos = Vec2.new(pos.x, pos.y)

    local marked = {}
    local function chk(pos)
        return not self:is_solid(pos) and
                (not marked[pos.x] or not marked[pos.x][pos.y])
    end

    for i = 1, amount do
        if pos.y < 1 then
            -- hit top of map
            pos.y = 1
            for j = 2, self:get_width() do
                if chk(Vec2.new(pos.x - j, pos.y)) then
                    pos.x = pos.x - j
                    break
                end
                if chk(Vec2.new(pos.x + j, pos.y)) then
                    pos.x = pos.x + j
                    break
                end
            end
            marked[pos.x] = marked[pos.x] or {}
            marked[pos.x][pos.y] = true
        end

        -- nx keeps track of where to start filling next layer
        local nx = pos.x
        if chk(Vec2.new(pos.x, pos.y + 1)) then
            pos.y = pos.y + 1
        elseif chk(Vec2.new(pos.x - 1, pos.y)) then
            pos.x = pos.x - 1
        elseif chk(Vec2.new(pos.x + 1, pos.y)) then
            pos.x = pos.x + 1
        else
            for j = pos.x, self:get_width() do
                if nx == pos.x and chk(Vec2.new(j, pos.y - 1)) then
                    nx = j
                end
                if chk(Vec2.new(j, pos.y)) then
                    pos.x = j
                    break
                elseif not marked[j] or not marked[j][pos.y] then
                    -- hit wall, try other direction
                    for k = pos.x, 0, -1 do
                        if nx == pos.x and chk(Vec2.new(k, pos.y - 1)) then
                            nx = k
                        end
                        if chk(Vec2.new(k, pos.y)) then
                            pos.x = k
                            break
                        elseif not marked[k] or not marked[k][pos.y] then
                            pos.y = pos.y - 1
                            pos.x = nx
                            break
                        end
                    end
                    break
                end
            end
        end
        marked[pos.x] = marked[pos.x] or {}
        marked[pos.x][pos.y] = true
    end

    for x, _ in pairs(marked) do
        for y, _ in pairs(marked[x]) do
            self:set_at(Vec2.new(x, y), Terrain.DIRT)
        end
    end
end

function Terrain:set_all(land)
    for x = 1, self:get_width() do
        for y = 1, self:get_height() do
            self:set_at(Vec2.new(x, y), land[(y - 1) * self:get_width() + x])
        end
    end
end

function Terrain:get_all()
    return self.delegate:get_all()
end

return Terrain
