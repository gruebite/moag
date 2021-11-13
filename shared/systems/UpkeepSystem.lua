--[[
UpkeepSystem periodically reports memory usage and collects garbage.
--]]

local UpkeepSystem = {}

function UpkeepSystem:init(args)
    self.gc_interval = 5
end

-- EVENTS

function UpkeepSystem:update(dt)
    self.gc_interval = self.gc_interval - dt
    if self.gc_interval <= 0 then
        local before = collectgarbage("count")
        collectgarbage()
        local after = collectgarbage("count")
        print(("gc run: %.2fkb -> %.2fkb"):format(before, after))
        self.gc_interval = 10
    end
end

return UpkeepSystem
