
local ChunkKind = require("shared.ChunkKind")

local ServerSystem = require(..., "ServerSystem")

local NotifySystem = {}

-- EVENTS

function NotifySystem:notify(msg)
    local server = self.pool:getSystem(ServerSystem)
    server.host:broadcast(table.serialize({{
        -- unused for now
        kind = ChunkKind.NOTIFICATION,
        type = 0,
        message = msg
    }}), 0, "reliable")
end

return NotifySystem
