--[[
Manages collisions for each entity type: bullets, crate, rovers. This
could potentionally be split up into BulletSystem, CrateSystem, etc.
--]]
local conf = require("conf")

local Vec2 = require("shared.Vec2")
local nentities = require("shared.nentities")
local entity_factory = require("shared.entity_factory")

local CollisionSystem = {}

function CollisionSystem:init(args)

end

-- EVENTS

function CollisionSystem:collision(src, pos, tar)
    if src.bullet then
        self.pool:queue(entity_factory.explosion(src))
        if src.bullet.cluster then
            local b = src.bullet.cluster
            local c = src.bullet.cluster_count
            for i = 0, c - 1 do
                self.pool:queue(entity_factory.bullet(
                        b, src.pos,
                        src.vel:scale(0.5):add(
                                src.vel:magnitude() * math.cos(i * math.pi / (c / 2)),
                                src.vel:magnitude() * math.sin(i * math.pi / (c / 2))),
                        src.bullet.owner))
            end
        end

        if not src.bullet.health then
            src.destroyed = true
            self.pool:emit("entity_destroyed", src)
        else
            src.bullet.health = src.bullet.health - 1
            if src.bullet.health <= 0 then
                src.destroyed = true
                self.pool:emit("entity_destroyed", src)
            end
        end
    elseif src.explosion and tar and tar.player and not tar.dead then
        if not src.explosion.safe then
            -- TODO How can we do this better? Static entities with nicks?
            if type(src.explosion.owner) == "number" then
                if nentities:get(src.explosion.owner) then
                    self.pool:emit("entity_killed", tar, nentities:get(src.explosion.owner))
                else
                    -- DC'd or something.
                    self.pool:emit("entity_killed", tar, "<unknown>")
                end
            else
                self.pool:emit("entity_killed", tar, src.explosion.owner)
            end
        end
    elseif src.crate and tar and tar.rover then
            tar.rover.special_bullet = src.crate.bullet
            tar.rover.special_ammo = src.crate.ammo
            if tar.network then
                tar.network.deltas["rover.special_bullet"] = true
                tar.network.deltas["rover.special_ammo"] = true
                tar.network.force = true
            end
            self.pool:emit("notify", "* " .. tar.nick .. " got " .. src.crate.bullet)
            src.destroyed = true
            self.pool:emit("entity_destroyed", src)
    elseif src.crate and tar and tar.bullet then
        self.pool:queue(
                entity_factory.bullet(
                        src.crate.bullet, src.pos, Vec2.new(0, 0), tar.bullet.owner))
        src.destroyed = true
        self.pool:emit("entity_destroyed", src)
    elseif src.crate and tar and tar.explosion then
        self.pool:queue(
                entity_factory.bullet(
                        src.crate.bullet, src.pos, Vec2.new(0, 0), tar.explosion.owner))
        src.destroyed = true
        self.pool:emit("entity_destroyed", src)
    end
end

return CollisionSystem