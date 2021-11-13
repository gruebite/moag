
local DestroyedSystem = {}

function DestroyedSystem:init(args)
end

-- EVENTS

function DestroyedSystem:entity_destroyed(ent)
    if not ent.when_destroyed then
        return
    end

    if ent.when_destroyed.spawns then
        for _, child in ipairs(ent.when_destroyed.spawns) do
            if child.pos and ent.pos then
                child.pos = child.pos:add(ent.pos)
            end
            if child.vel and ent.vel then
                print(child.vel)
                child.vel = ent.vel:scale(child.vel)
            end
            self.pool:queue(child)
        end
    end
end

return DestroyedSystem