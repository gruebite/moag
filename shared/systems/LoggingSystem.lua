--[[
LoggingSystem reports when entities are added and removed.
--]]

local LoggingSystem = {}

function LoggingSystem:init(args)
    self.terra = args.terra
end

-- EVENTS

function LoggingSystem:add(ent)
    local network = ent.network and (" net %d;"):format(ent.network.id) or ""
    local rover = ent.rover and (" rover;") or ""
    local bullet = ent.bullet and (" bullet;") or ""
    local crate = ent.crate and (" crate;") or ""
    local explosion = ent.explosion and (" explosion;") or ""
    local total = (" (%d entities)"):format(#self.pool.entities)
    print(("added %s;"):format(tostring(ent)) ..
            network .. rover .. bullet .. crate .. explosion .. total)
end

function LoggingSystem:remove(ent)
    local network = ent.network and (" net %d;"):format(ent.network.id) or ""
    local rover = ent.rover and (" rover;") or ""
    local bullet = ent.bullet and (" bullet;") or ""
    local crate = ent.crate and (" crate;") or ""
    local explosion = ent.explosion and (" explosion;") or ""
     -- -1 because "remove" is called before list removal
    local total = (" (%d entities)"):format(#self.pool.entities - 1)
    print(("removed %s;"):format(tostring(ent)) ..
            network .. rover .. bullet .. crate .. explosion .. total)
end

return LoggingSystem