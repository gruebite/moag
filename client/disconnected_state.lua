
local suit = require("lib.suit")

local resources = require(..., "resources")
local state = require(..., "state")

local lg = love.graphics
local switch_after

local function enter(host, port)
    switch_after = 2
end

function love.update(dt)
    local w = lg.getWidth()
    local h = lg.getHeight()
    local cw = w / 3
    suit.layout:reset(cw, h / 2)
    suit.Label("disconnected from server...", { align = "center" }, suit.layout:row(cw, 0))

    switch_after = switch_after - dt
    if switch_after <= 0 then
        state.switch("client.multiplayer_state")
    end
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
