local conf = require("conf")
local enet = require("enet")

local suit = require("lib.suit")

local ChunkKind = require("shared.ChunkKind")
local Vec2 = require("shared.Vec2")

local resources = require(..., "resources")
local state = require(..., "state")

local lg = love.graphics

local host
local peer
local nick
local color
local connect_timeout
local happening

local function enter(h, p, n, c)
    host = enet.host_create()
    host:compress_with_range_coder()
    print("connecting to '" .. h .. ":" .. p .. "'")
    peer = host:connect(h .. ":" .. p)
    nick = n
    color = c
    connect_timeout = conf.CONNECT_TIMEOUT
    happening = "connecting"
end

function love.update(dt)
    -- pull updates from server
    local event = host:service(0)
    while event do
        if event then
            if event.type == "connect" then
                happening = "loading"
                peer:send(table.serialize {
                    kind = ChunkKind.REQUEST_CONNECT,
                    nick = nick,
                    color = color
                })
                print("connected to", event.peer)
            elseif event.type == "disconnect" then
                happening = "disconnected"
                print("disconnected from", event.peer)
            elseif event.type == "receive" then
                local batch = table.deserialize(event.data)
                state.switch("client.game_state", batch, host, peer)
                return
            end
        end
        event = host:service(0)
    end

    if happening == "connecting" then
        connect_timeout = connect_timeout - dt
        if connect_timeout <= 0 then
            state.switch("client.timedout_state")
            return
        end
    end

    local w = lg.getWidth()
    local h = lg.getHeight()
    local cw = w / 3
    suit.layout:reset(cw, h / 2)

    suit.Label(happening .. "...", { align = "center" }, suit.layout:row(cw, 0))
end

function love.draw()
    lg.setFont(resources:get("medium_font"))
    suit.draw()
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

return {
    enter = enter,
    exit = state.unload_love
}
