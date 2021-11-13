
local conf = require("conf")

local InterpolationSystem = {}

function InterpolationSystem:init(args)

end

-- EVENTS

function InterpolationSystem:update(dt)
    for _, ent in ipairs(self.pool.groups.interpolation.entities) do
        if not ent.interpolation.alpha then
            ent.interpolation.alpha = 0
        end
        if not ent.interpolation.frames or ent.dead then
            ent.interpolation.frames = {}
        end

        if ent.interpolation.synced then
            table.insert(ent.interpolation.frames, ent.pos)
            ent.interpolation.synced = false
        end

        if #ent.interpolation.frames >= 2 then
            ent.pos = ent.interpolation.frames[1]:lerp(ent.interpolation.frames[2], ent.interpolation.alpha)
            ent.interpolation.alpha = ent.interpolation.alpha + (dt * (1 / conf.SERVER_SAMPLE_RATE) * 1.0)
            if ent.interpolation.alpha > 1.0 or #ent.interpolation.frames >= 3 then
                ent.interpolation.alpha = ent.interpolation.alpha - 1
                if #ent.interpolation.frames > 1 then
                    table.remove(ent.interpolation.frames, 1)
                end
                -- If we've gone over, just take this as the new pos.
                --ent.interpolation.frames[1] = ent.pos
            end
        end
    end
end

return InterpolationSystem