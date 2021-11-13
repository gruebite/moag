
local LifetimeSystem = {}

function LifetimeSystem:init(args)

end

-- Events

function LifetimeSystem:update(dt)
    for _, ent in ipairs(self.pool.groups.lifetime.entities) do
        ent.lifetime = ent.lifetime - dt
        if ent.lifetime <= 0 then
            ent.destroyed = true
            self.pool:emit("entity_destroyed", ent)
        end
    end
end

return LifetimeSystem