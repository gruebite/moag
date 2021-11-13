--[[
Main menu.
--]]
local suit = require("lib.suit")

local resources = require(..., "resources")
local state = require(..., "state")

local lg = love.graphics

function love.update(dt)
    local w = lg.getWidth()
    local h = lg.getHeight()
    suit.layout:reset(w / 3, h / 2)
    suit.layout:padding(30, 30)

    if suit.Button("Multiplayer", suit.layout:row(w / 3, 30)).hit then
        state.switch("client.multiplayer_state")
    end

    if suit.Button("Options", suit.layout:row()).hit then
        state.switch("client.options_state")
    end

    if suit.Button("Exit", suit.layout:row()).hit then
        love.event.quit()
    end
end

function love.draw()
    lg.setFont(resources:get("medium_font"))
    local w = lg.getWidth()
    local tw = resources:get("medium_font"):getWidth([[_____ ______   ________  ________  ________      ]])
    local th = resources:get("medium_font"):getHeight()
    lg.print([[_____ ______   ________  ________  ________      ]], w / 2 - tw / 2, 100 + th * 0)
    lg.print([[|\   _ \  _   \|\   __  \|\   __  \|\   ____\    ]], w / 2 - tw / 2, 100 + th * 1)
    lg.print([[\ \  \\\__\ \  \ \  \|\  \ \  \|\  \ \  \___|    ]], w / 2 - tw / 2, 100 + th * 2)
    lg.print([[ \ \  \\|__| \  \ \  \\\  \ \   __  \ \  \  ___  ]], w / 2 - tw / 2, 100 + th * 3)
    lg.print([[  \ \  \    \ \  \ \  \\\  \ \  \ \  \ \  \|\  \ ]], w / 2 - tw / 2, 100 + th * 4)
    lg.print([[   \ \__\    \ \__\ \_______\ \__\ \__\ \_______\]], w / 2 - tw / 2, 100 + th * 5)
    lg.print([[    \|__|     \|__|\|_______|\|__|\|__|\|_______|]], w / 2 - tw / 2, 100 + th * 6)

    suit.draw()
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

return {
    exit = state.unload_love
}
