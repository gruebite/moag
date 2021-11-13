local conf = require("conf")
local enet = require("enet")

local bit_set = require("shared.bit_set")
local Vec2 = require("shared.Vec2")
local Timer = require("shared.Timer")

local InputKind = require("shared.InputKind")
local ChunkKind = require("shared.ChunkKind")
local entity_factory = require("shared.entity_factory")
local nentities = require("shared.nentities")

local function build_delta(ent, chunk, deltas)
    for keys, _ in pairs(deltas) do
        local chunk_iter = chunk
        local ent_iter = ent
        for key in string.gmatch(keys, "[^.]+") do
            if type(ent_iter[key]) == "table" then
                chunk_iter[key] = chunk_iter[key] or {}
                chunk_iter = chunk_iter[key]
                ent_iter = ent_iter[key]
            else
                chunk_iter[key] = ent_iter[key]
                ent_iter = ent_iter[key]
            end
        end
        if type(ent_iter) == "table" then
            table.deepcopy(ent_iter, chunk_iter)
        end
    end
end

local function chunkify_create(ent)
    local chunk = {
        id = ent.network.id,
        data = {}
    }
    build_delta(ent, chunk.data, ent.network.snapshot)
    if ent.bullet then
        chunk.kind = ChunkKind.BULLET_CREATE
    elseif ent.rover then
        chunk.kind = ChunkKind.ROVER_CREATE
    elseif ent.crate then
        chunk.kind = ChunkKind.CRATE_CREATE
    elseif ent.explosion then
        chunk.kind = ChunkKind.EXPLOSION_CREATE
    end
    return chunk
end

local function chunkify_update(ent)
    local chunk = {
        id = ent.network.id,
        kind = ChunkKind.ENTITY_UPDATE,
        data = {}
    }
    build_delta(ent, chunk.data, ent.network.deltas)
    return chunk
end

local function chunkify_destroy(ent)
    return {
        kind = ChunkKind.ENTITY_DESTROY,
        id = ent.network.id
    }
end

local function chunkify_terrain(terra)
    return {
        kind = ChunkKind.TERRAIN,
        terrain = terra:get_all()
    }
end

local ServerSystem = {}

function ServerSystem:init(args)
    self.terra = args.terra
    self.host = enet.host_create("*:" .. args.port)
    self.host:compress_with_range_coder()
    self.clients = {}
    self.created = {}
    self.destroyed = {}
    self.pulse_timer = Timer.pulse(conf.SERVER_SAMPLE_RATE)


    self.log_bandwidth_timer = Timer.pulse(5.0)
    self.last_sent = 0
    self.last_recv = 0
end

function ServerSystem:process_chunk(data, player)
    if data.kind == ChunkKind.PLAYER_INPUT then
        local minangle = player.rover.facingleft and 180 or 270
        local maxangle = player.rover.facingleft and 270 or 360
        if bit_set.has(data.state, InputKind.MOVE_LEFT) then
            player.vel.x = -player.rover.speed
            if not player.rover.facingleft then
                player.rover.turret_angle = 180 - player.rover.turret_angle
                if player.rover.turret_angle < 0 then
                    player.rover.turret_angle = player.rover.turret_angle + 360
                end
                player.rover.facingleft = true
                player.network.deltas["rover.turret_angle"] = true
            end
        elseif bit_set.has(data.state, InputKind.MOVE_RIGHT) then
            player.vel.x = player.rover.speed
            if player.rover.facingleft then
                player.rover.turret_angle = 180 - player.rover.turret_angle
                if player.rover.turret_angle < 0 then
                    player.rover.turret_angle = player.rover.turret_angle + 360
                end
                player.rover.facingleft = false
                player.network.deltas["rover.turret_angle"] = true
            end
        else
            player.vel.x = 0
        end

        if bit_set.has(data.state, InputKind.MOVE_UP) then
            player.rover.turret_angle = player.rover.turret_angle + (player.rover.facingleft and 1 or -1)
            if player.rover.turret_angle < minangle then
                player.rover.turret_angle = minangle
            elseif player.rover.turret_angle > maxangle then
                player.rover.turret_angle = maxangle
            end
            player.network.deltas["rover.turret_angle"] = true
        elseif bit_set.has(data.state, InputKind.MOVE_DOWN) then
            player.rover.turret_angle = player.rover.turret_angle + (player.rover.facingleft and -1 or 1)
            if player.rover.turret_angle < minangle then
                player.rover.turret_angle = minangle
            elseif player.rover.turret_angle > maxangle then
                player.rover.turret_angle = maxangle
            end
            player.network.deltas["rover.turret_angle"] = true
        end

        if data.fire then
            if not player.dead then
                local rads = math.rad(player.rover.turret_angle)
                local offset = Vec2.new(conf.TURRET.WIDTH * 1.5, 0):rotate(rads)
                local bullet
                if data.special and player.rover.special_ammo > 0 then
                    bullet = player.rover.special_bullet
                    player.rover.special_ammo = player.rover.special_ammo - 1
                    if player.network then
                        player.network.deltas["rover.special_ammo"] = true
                        player.network.force = true
                    end
                else
                    bullet = player.rover.main_bullet
                end
                self.pool:queue(entity_factory.bullet(
                        bullet,
                        player.pos:add(0, -conf.ROVER.HEIGHT):add(offset),
                        Vec2.new(data.fire_power * 200, 0):rotate(rads),
                        player.network.id))
            end
        end
        
        if bit_set.has(data.state, InputKind.BOOST)  then
            if not player.physics.in_air or player.physics.climbing then
                self.pool:queue(entity_factory.explosion(entity_factory.bullet(
                        "safe missile",
                        player.pos:add(0, -conf.ROVER.HEIGHT),
                        Vec2.new(0, 0),
                        player.network.id)))
                player.vel.y = -player.rover.boost_speed
            end
        end

        player.render.children.turret.rotation = player.rover.turret_angle
    elseif data.kind == ChunkKind.PLAYER_CHAT then
        self.pool:emit("notify", player.nick .. "> " .. data.text, "chat")
    end
end

function ServerSystem:_send_full_snapshot(peer)
    local batch = {}
    table.insert(batch, chunkify_terrain(self.terra))
    for _, ent in nentities:iter() do
        local c = chunkify_create(ent)
        if c then
            table.insert(batch, c)
        end
    end
    table.insert(batch, { kind = ChunkKind.CONNECT, you = peer:index() })

    peer:send(table.serialize(batch), 0, "reliable")
end

function ServerSystem:_connect_client(peer)
    local client = self.pool:queue(entity_factory.player(peer:index()))
    client.dead = true
    self.clients[peer:index()] = client
end

function ServerSystem:_disconnect_client(peer)
    local player = self.clients[peer:index()]
    self.pool:emit("player_disconnected", player.network.id)
    player.destroyed = true
    self.pool:emit("entity_destroyed", player)
end

-- EVENTS

function ServerSystem:addToGroup(group, ent)
    if group == "network" then
        setmetatable(ent, getmetatable(ent) or {})
        nentities:add(ent)
        table.insert(self.created, ent)
    end
end

function ServerSystem:removeFromGroup(group, ent)
    if group == "network" then
        nentities:remove(ent)
        table.insert(self.destroyed, ent)
    end
end

function ServerSystem:update(dt)
    local event = self.host:service(0)
    while event do
        if event.type == "connect" then
            -- Wait for request connect.
            self:_connect_client(event.peer)
        elseif event.type == "disconnect" then
            self:_disconnect_client(event.peer)
        elseif event.type == "receive" then
            local chunk = table.deserialize(event.data)
            if chunk.kind == ChunkKind.REQUEST_CONNECT then
                local client = self.clients[event.peer:index()]
                if chunk.nick and chunk.nick ~= "" then
                    client.nick = chunk.nick
                end
                client.color = chunk.color
                client.dead = nil
                self:_send_full_snapshot(event.peer)
                self.pool:emit("notify", "* " .. client.nick .. " has connected", "notification")
                self.pool:emit("player_connected", client.network.id)
                self.pool:queue(entity_factory.explosion(
                    entity_factory.bullet("safe warhead", client.pos, Vec2.new(0, 0), client.network.id)
                ))
            else
                self:process_chunk(chunk, self.clients[event.peer:index()])
            end
        end
        event = self.host:service(0)
    end

    if self.log_bandwidth_timer:tick(dt) then
        print(
                "incoming: ", tostring((self.host:total_received_data() - self.last_recv) / 1000) .. "kbps",
                "outgoing: ", tostring((self.host:total_sent_data() - self.last_sent) / 1000) .. "kbps")
        self.last_sent = self.host:total_sent_data()
        self.last_recv = self.host:total_received_data()
    end

    -- Push

    if not self.pulse_timer:tick(dt) then
        return
    end

    local reliable_batch = {}
    local unreliable_batch = {}

    for _, ent in pairs(self.created) do
        table.insert(reliable_batch, chunkify_create(ent))
    end
    self.created = {}

    for _, ent in nentities:iter() do
        if next(ent.network.deltas) then
            -- currently explosions return nil (they don't update)
            local c = chunkify_update(ent)
            if c then
                if ent.network.force then
                    table.insert(reliable_batch, c)
                    ent.network.force = false
                else
                    table.insert(unreliable_batch, c)
                end
            end
            ent.network.deltas = {}
        end
    end

    for _, ent in pairs(self.destroyed) do
        table.insert(reliable_batch, chunkify_destroy(ent))
    end
    self.destroyed = {}

    if #reliable_batch ~= 0 then
        self.host:broadcast(table.serialize(reliable_batch), 0, "reliable")
    end
    if #unreliable_batch ~= 0 then
        self.host:broadcast(table.serialize(unreliable_batch), 0, "unreliable")
    end

    self.host:flush()
end

return ServerSystem
