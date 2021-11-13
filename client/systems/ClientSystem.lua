local conf = require("conf")
local enet = require("enet")

local ColorKind = require("shared.ColorKind")
local ChunkKind = require("shared.ChunkKind")
local InputKind = require("shared.InputKind")
local Vec2 = require("shared.Vec2")
local entity_factory = require("shared.entity_factory")
local nentities = require("shared.nentities")

local ClientSystem = {}

function ClientSystem:init(args)
    self.terra = args.terra
    self.chatbox = args.chatbox
    self.host = args.host
    self.peer = args.peer
end

function ClientSystem:send_chat(text)
    self.peer:send(table.serialize({
        kind = ChunkKind.PLAYER_CHAT,
        text = text
    }))
end

function ClientSystem:disconnect()
    self.peer:disconnect()
    self.host:flush()
end

function ClientSystem:process_chunk(chunk)
    if chunk.kind == ChunkKind.CONNECT then
        self.you = chunk.you
    elseif chunk.kind == ChunkKind.TERRAIN then
        self.terra:set_all(chunk.terrain)
    elseif chunk.kind == ChunkKind.BULLET_CREATE then
        local ent = entity_factory.bullet("missile", Vec2.new(0, 0), Vec2.new(0, 0))
        ent.network.id = chunk.id
        table.deepcopy(chunk.data, ent)
        if ent.interpolation then
            ent.interpolation.synced = true
        end
        self.pool:queue(ent)
        nentities:add(ent)
    elseif chunk.kind == ChunkKind.CRATE_CREATE then
        local ent = entity_factory.crate()
        ent.network.id = chunk.id
        table.deepcopy(chunk.data, ent)
        if ent.interpolation then
            ent.interpolation.synced = true
        end
        self.pool:queue(ent)
        nentities:add(ent)
    elseif chunk.kind == ChunkKind.EXPLOSION_CREATE then
        local ent = entity_factory.explosion()
        ent.network.id = chunk.id
        table.deepcopy(chunk.data, ent)
        self.pool:queue(ent)
        nentities:add(ent)
    elseif chunk.kind == ChunkKind.ROVER_CREATE then
        local ent = entity_factory.player(chunk.id)
        table.deepcopy(chunk.data, ent)
        ent.render.children.turret.rotation = ent.rover.turret_angle
        ent.render.tint = ColorKind.LOOKUP[ent.color]
        if ent.interpolation then
            ent.interpolation.synced = true
        end
        self.pool:queue(ent)
        nentities:add(ent)
    elseif chunk.kind == ChunkKind.ENTITY_UPDATE then
        local ent = nentities:get(chunk.id)
        table.deepcopy(chunk.data, ent)
        -- TODO This is ugly special case, perhaps have two entities synced by
        -- network and have one be a child of the other? Rendering checks
        -- parent positions (and parents of parents)
        if ent.rover then
            ent.render.children.turret.rotation = ent.rover.turret_angle
        end
        if ent.interpolation then
            ent.interpolation.synced = true
        end
        self.pool:queue(ent)
    elseif chunk.kind == ChunkKind.ENTITY_DESTROY then
        nentities:get(chunk.id).destroyed = true
        nentities:remove(chunk.id)
    elseif chunk.kind == ChunkKind.NOTIFICATION then
        self.chatbox:add_line(chunk.message)
    end
end

-- EVENTS

function ClientSystem:addToGroup(group, ent)
    if group == "network" then
        nentities:add(ent)
    end
end

function ClientSystem:removeFromGroup(group, ent)
    if group == "network" then
        nentities:remove(ent)
    end
end

function ClientSystem:update(dt)
    local event = self.host:service(0)
    while event do
        if event then
            if event.type == "connect" then
                -- Already connected by this point.
                assert(false, "bug")
            elseif event.type == "disconnect" then
                print("disconnected from", event.peer)
                self.pool:emit("disconnected")
            elseif event.type == "receive" then
                local batch = table.deserialize(event.data)
                for _, c in ipairs(batch) do
                    self:process_chunk(c)
                end
                --[[print(string.format("packet length: %d bytes; payload length: %d",
                        #event.data,
                        #batch))--]]
            end
        end
        event = self.host:service(0)
    end
end

return ClientSystem
