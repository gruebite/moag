
local conf = require("conf")

local Vec2 = require("shared.Vec2")
local entity_factory = require("shared.entity_factory")

local RespawnSystem = {}

-- EVENTS

function RespawnSystem:entity_killed(tar, src)
    if not tar.respawn then
        return
    end

    tar.pos:set(math.random(30, conf.WIDTH - 30), 30)
    tar.vel:set(0, 0)
    tar.dead = true
    tar.respawn.after = 3
    tar.rover.main_bullet = "missile"
    if tar.network then
        tar.network.deltas["pos"] = true
        tar.network.deltas["dead"] = true
        tar.network.deltas["rover.main_bullet"] = true
        tar.network.force = true
    end
    self.pool:queue(tar)
end

function RespawnSystem:update(dt)
    for _, ent in ipairs(self.pool.groups.respawn.entities) do
        if ent.respawn.after then
            ent.respawn.after = ent.respawn.after - dt
            if ent.respawn.after <= 0 then
                ent.respawn.after = nil
                ent.dead = false
                if ent.network then
                    ent.network.deltas["dead"] = true
                    ent.network.force = true
                end
                self.pool:queue(ent)
                self.pool:queue(entity_factory.explosion(
                    entity_factory.bullet("safe warhead", ent.pos, Vec2.new(0, 0), ent.network.id)
                ))
            end
        end
    end
end

return RespawnSystem
