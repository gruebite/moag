local conf = require("conf")

local entity_factory = require("shared.entity_factory")

local CrateSpawnSystem = {}

function CrateSpawnSystem:init(args)
    self:calc_spawn_timer()
end

function CrateSpawnSystem:calc_spawn_timer()
    self.spawn_timer = math.random(
            conf.MIN_CRATE_SPAWN_TIME,
            conf.MAX_CRATE_SPAWN_TIME)
end

-- EVENTS

function CrateSpawnSystem:update(dt)
    self.spawn_timer = self.spawn_timer - dt
    if self.spawn_timer <= 0 then
        self:calc_spawn_timer()
        self.pool:queue(entity_factory.crate())
    end
end

return CrateSpawnSystem
