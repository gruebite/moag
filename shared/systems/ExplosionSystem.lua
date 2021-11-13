local conf = require("conf")

local ExplosionKind = require("shared.ExplosionKind")
local Vec2 = require("shared.Vec2")

local ExplosionSystem = {}

function ExplosionSystem:init(args)
    self.terra = args.terra
end

-- EVENTS

function ExplosionSystem:addToGroup(group, ent)
    if group == "explosion" then
        if ent.explosion.kind == ExplosionKind.LIQUID then
            self.terra:pour_liquid(ent.pos, ent.explosion.amount)
        elseif ent.explosion.kind == ExplosionKind.COLLAPSE then
            self.terra:collapse(ent.pos, ent.explosion.radius)
        else
            self.terra:set_circle(ent.pos, ent.explosion.radius, ent.explosion.fill)
        end
    end
end

return ExplosionSystem
