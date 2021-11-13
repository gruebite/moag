
local resources = require("client.resources")

local EffectsSystem = {}

-- EVENTS

function EffectsSystem:update(dt)
    for _, ent in ipairs(self.pool.groups.effects.entities) do
        local destroy = true
        for _, v in pairs(ent.effects) do
            if not v:update(dt) then
                destroy = false
            end
        end
        if destroy then
            ent.destroyed = true
        end
    end
end

return EffectsSystem