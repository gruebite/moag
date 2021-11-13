--[[
Handles physics. This system is quite complex and could use some simplifying.
There are are a lot of events fired and flags set here.

FLAGS
    physics.climbing = false -- True when climbing going up a wall.
    physics.falling = false -- True when y velocity > 0.
    physics.in_air = false -- True when no land directly below.

COLLISION
    physics.collision_shape = "rect" or "circle"
    physics.collides_with = Set.new()
    physics.collision_mask = Set.new()

ABILITIES (nil/flase by default)
    physics.ghost -- Land does not set vel.y to 0. Still emits collision.
    physics.can_climb -- When moving against a terrain wall, |x| velocity will become -y.
    physics.ignores_gravity -- Gravity will not alter velocity.
    physics.ignores_velocity -- Velocity will not alter position.
    -- Out of bounds. -1 is left/right, -2 is up, -3 is down
    physics.oob_flags = {
        [1] = "exists" or "wraps" or "collides" (default "destructs")
        [2] = "exists" or "wraps" or "collides"
        [3] = "exists" or "wraps" or "collides"
    }
    physics.destroyed_when_falling -- Destroyed when y velocity > 0.
    physics.moves_through_terrain -- Like ghost, but will not emit collisions.
    physics.bounces = false -- Collisions with terrain will bounce velocity away.
--]]
local conf = require("conf")

local Set = require("shared.Set")
local Vec2 = require("shared.Vec2")
local Timer = require("shared.Timer")

local Line = require("server.Line")

local function bounce(terra, ent, pos)
    pos.x = math.floor(pos.x)
    pos.y = math.floor(pos.y)

    local h = 0

    if terra:is_solid(pos:add(-1, -1)) then
        h = bit.bor(h, 0x00000080)
    end
    if terra:is_solid(pos:add(0, -1)) then
        h = bit.bor(h, 0x00000040)
    end
    if terra:is_solid(pos:add(1, -1)) then
        h = bit.bor(h, 0x00000020)
    end
    if terra:is_solid(pos:add(-1, 0)) then
        h = bit.bor(h, 0x00000010)
    end
    if terra:is_solid(pos:add(1, 0)) then
        h = bit.bor(h, 0x00000008)
    end
    if terra:is_solid(pos:add(-1, 1)) then
        h = bit.bor(h, 0x00000004)
    end
    if terra:is_solid(pos:add(0, 1)) then
        h = bit.bor(h, 0x00000002)
    end
    if terra:is_solid(pos:add(1, 1)) then
        h = bit.bor(h, 0x00000001)
    end

    local irt2 = 0.70710678
    local vx = ent.vel.x
    local vy = ent.vel.y

    if h == 0 then
        return
    elseif h == 0x07 or h == 0xe0 or h == 0x02 or h == 0x40 then
        ent.vel.y = -vy
    elseif h == 0x94 or h == 0x29 or h == 0x10 or h == 0x08 then
        ent.vel.x = -vx
    elseif h == 0x16 or h == 0x68 or h == 0x04 or h == 0x20 then
        ent.vel.y = vx
        ent.vel.x = vy
    elseif h == 0xd0 or h == 0x0b or h == 0x80 or h == 0x01 then
        ent.vel.y = -vx
        ent.vel.x = -vy
    elseif h == 0x17 or h == 0xe8 or h == 0x06 or h == 0x60 then
        ent.vel.x = math.abs(vx) * irt2 + vy * irt2
        ent.vel.y = -vy * irt2 + vx * irt2
    elseif h == 0x96 or h == 0x69 or h == 0x14 or h == 0x28 then
        ent.vel.x = -vx * irt2 + vy * irt2
        ent.vel.y = math.abs(vy) * irt2 + vx * irt2
    elseif h == 0xf0 or h == 0x0f or h == 0xc0 or h == 0x03 then
        ent.vel.x = math.abs(vx) * irt2 - vy * irt2
        ent.vel.y = -vy * irt2 - vx * irt2
    elseif h == 0xd4 or h == 0x2b or h == 0x90 or h == 0x09 then
        ent.vel.x = -vx * irt2 - vy * irt2
        ent.vel.y = math.abs(vy) * irt2 - vx * irt2
    else
        ent.vel.x = -vx
        ent.vel.y = -vy
    end
end

local function rectangles_interect(atl, abr, btl, bbr)
    return atl.x < bbr.x and abr.x > btl.x and
            atl.y < bbr.y and abr.y > btl.y
end

local function circles_intersect(cen1, r1, cen2, r2)
    return cen1:distance(cen2) < r1 + r2
end

local function rect_circ_intersect(tl, br, cen, r)
    local dx = cen.x - math.max(tl.x, math.min(br.x, cen.x))
    local dy = cen.y - math.max(tl.y, math.min(br.y, cen.y))
    return (dx * dx + dy * dy) < (r * r)
end

local function overlaps(a, b)
    -- we assume center bottom for position, so we move back to topleft
    local apos = a.pos:cpy()
    local bpos = b.pos:cpy()
    if a.offset and a.physics.collision_shape ~= "circle" then
        apos.x = apos.x - (a.siz.x * a.offset.x)
        apos.y = apos.y - (a.siz.y * a.offset.y)
    end
    if b.offset and b.physics.collision_shape ~= "circle" then
        bpos.x = bpos.x - (b.siz.x * b.offset.x)
        bpos.y = bpos.y - (b.siz.y * b.offset.y)
    end
    local ashape = a.physics.collision_shape or "rect"
    local bshape = b.physics.collision_shape or "rect"
    if ashape == bshape then
        if ashape == "rect" then
            return rectangles_interect(
                    apos, apos:add(a.siz),
                    bpos, bpos:add(b.siz))
        else
            -- we take the max in any ellipsoid kinda shape
            return circles_intersect(
                    apos, math.max(a.siz.x, a.size.y),
                    bpos, math.max(b.siz.x, b.size.y))
        end
    else
        if ashape == "rect" then
            return rect_circ_intersect(
                    apos,
                    apos:add(a.siz),
                    bpos,
                    math.max(b.siz.x, b.siz.y))
        else
            return rect_circ_intersect(
                    bpos,
                    bpos:add(b.siz),
                    apos,
                    math.max(a.siz.x, a.siz.y))
        end
    end
end

local function is_obstructed(ent, terra, pos)
    if terra:is_solid(pos) and not ent.physics.moves_through_terrain then
        return true
    end
    local tile = -terra:get_at(pos)
    if ent.physics.oob_flags and ent.physics.oob_flags[tile] == "collides" then
        return true
    end
    return false
end

local function is_collision(e1, e2)
    local with = e1.physics.collides_with or Set.new()
    local mask = e2.physics.collision_mask or Set.new()
    if with:intersect(mask):get_size() > 0 then
        if overlaps(e1, e2) then
            return true
        end
    end
    return false
end

local PhysicsSystem = {}

function PhysicsSystem:init(args)
    self.terra = args.terra
    self._pulse_timer = Timer.pulse(conf.SERVER_GAME_RATE)
    self._accum_dt = 0
    self._masks = {}
end

function PhysicsSystem:_ents_with(ent)
    local with_iter = (ent.physics.collides_with or Set.new()):iter()
    local mask_iter = nil
    local with = with_iter()
    return function()
        if with then
            mask_iter, _ = next(self._masks[with] or {}, mask_iter)
            if mask_iter then
                return mask_iter
            else
                with = with_iter()
                if with then
                    mask_iter, _ = next(self._masks[with] or {}, mask_iter)
                    return mask_iter
                end
            end
        end
    end
end

-- EVENTS

function PhysicsSystem:addToGroup(group, ent)
    if group == "physics" then
        for mask in ent.physics.collision_mask:iter() do
            self._masks[mask] = self._masks[mask] or {}
            self._masks[mask][ent] = true
        end
    end
end

function PhysicsSystem:removeFromGroup(group, ent)
    if group == "physics" then
        for mask in ent.physics.collision_mask:iter() do
            self._masks[mask][ent] = nil
        end
    end
end

function PhysicsSystem:update(dt)
    self._accum_dt = self._accum_dt + dt
    if not self._pulse_timer:tick(dt) then
        return
    end

    dt = self._accum_dt
    self._accum_dt = 0
    for _, ent in ipairs(self.pool.groups.physics.entities) do
        ent.physics.climbing = false
        ent.physics.in_air = false
        ent.physics.falling = false

        if ent.dead then
            goto continue
        end

        if ent.physics.ignores_velocity then
            ent.vel:set(0, 0)
        end

        if not is_obstructed(ent, self.terra, ent.pos:add(0, 1)) then
            ent.physics.in_air = true
            if not ent.physics.ignores_gravity then
                local acc = Vec2.new(0, conf.GRAVITY):scale(dt)
                ent.vel = ent.vel:add(acc)
                if ent.vel.y > 0 then
                    ent.physics.falling = true
                    if ent.physics.destroyed_when_falling then
                        ent.destroyed = true
                        self.pool:emit("entity_destroyed", ent)
                    end
                end
            end
        end

        if ent.vel.x ~= 0 or ent.vel.y ~= 0 then
            -- Here we're assuming non-zero velocity means motion, but
            -- that may not be true for small movements.
            ent.network.deltas["pos"] = true
        end

        local delta = ent.vel:scale(dt)

        local xveldir = ent.vel.x > 0 and 1 or (ent.vel.x < 0 and -1 or 0)
        if xveldir ~= 0 and ent.physics.can_climb then
            if is_obstructed(ent, self.terra, ent.pos:add(xveldir, 0)) then
                delta = Vec2.new(0, -math.abs(ent.vel.x) * dt)
                ent.vel.y = 0
                ent.physics.climbing = true
            end
        end

        local npos = ent.pos:add(delta)

        local collided = {}
        local l = Line.new(ent.pos.x, ent.pos.y, npos.x, npos.y)
        for x, y in l:walk() do
            -- todo: add partitions
            for other in self:_ents_with(ent) do
                if ent ~= other then
                    if not collided[other] and is_collision(ent, other) then
                        self.pool:emit("collision", ent, Vec2.new(x, y), other)
                        collided[other] = true
                    end
                end
            end

            if is_obstructed(ent, self.terra, Vec2.new(x, y)) then
                self.pool:emit("collision", ent, Vec2.new(x, y))
                if ent.physics.bounces then
                    bounce(self.terra, ent, ent.pos:cpy())
                    ent.vel = ent.vel:scale(ent.physics.bounce_scale or 0.9)
                    self.pool:emit("entity_bounced", ent)
                else
                    if not ent.physics.ghost then
                        ent.vel.y = 0
                    end
                end
                -- Continue is passed the in_bounds check, which doesn't apply
                -- to this branch.
                goto continue
            end

            ent.pos:set(x, y)
        end
        ent.pos:set(npos)

        if not self.terra:in_bounds(ent.pos) then
            local tile = -self.terra:get_at(ent.pos)
            -- Default is to be destroyed.
            if not ent.physics.oob_flags or not ent.physics.oob_flags[tile] or ent.physics.oob_flags[tile] == "destructs" then
                ent.destroyed = true
                self.pool:emit("entity_destroyed", ent)
            elseif ent.physics.oob_flags then
                if ent.physics.oob_flags[tile] == "wraps" then
                    if tile == 1 then
                        while ent.pos.x <= 0 do
                            ent.pos.x = ent.pos.x + conf.WIDTH
                        end
                        while ent.pos.x > conf.WIDTH do
                            ent.pos.x = ent.pos.x - conf.WIDTH
                        end
                    elseif tile == 2 then
                        while ent.pos.y <= 0 do
                            ent.pos.y = ent.pos.x + conf.HEIGHT
                        end
                    elseif tile == 3 then
                        while ent.pos.y > conf.HEIGHT do
                            ent.pos.y = ent.pos.x - conf.HEIGHT
                        end
                    else
                        assert(false, "bug")
                    end
                end
            end
        end
        
        ::continue::
    end
end

return PhysicsSystem
