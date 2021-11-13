--[[
Client options menu.
--]]
local conf = require("conf")

local suit = require("lib.suit")

local resources = require(..., "resources")
local state = require(..., "state")

local lg = love.graphics

local effects = { checked = true }
local sound = { checked = true }

local saved

local function enter()
    saved, _ = love.filesystem.read("options_state.save")
    if saved then
        saved = table.deserialize(saved)
        effects.checked = saved.effects
        sound.checked = saved.sound
    end
end

function love.update(dt)
    local w = lg.getWidth()
    local h = lg.getHeight()
    local cw = w / 3
    suit.layout:reset(cw, h / 2)
    suit.layout:padding(0, 30)

    suit.layout:push(suit.layout:row(cw, 30))
    suit.Label("Sound", { align = "left" }, suit.layout:row(cw - 30, 30))
    if suit.Checkbox(sound, { align = "right" }, suit.layout:col(30)).hit then
        conf.PLAY_SOUND = sound.checked
    end
    suit.layout:pop()
    suit.layout:push(suit.layout:row(cw, 30))
    suit.Label("Effects", { align = "left" }, suit.layout:row(cw - 30, 30))
    if suit.Checkbox(effects, { align = "right" }, suit.layout:col(30)).hit then
        conf.EFFECTS = effects.checked
    end
    suit.layout:pop()
    if suit.Button("Back", suit.layout:row(cw * 5 / 12, 30)).hit then
        state.switch("client.main_state")
    end
    suit.layout:col(cw * 2 / 12)
    if suit.Button("Save", suit.layout:col(cw * 5 / 12)).hit then
        saved = saved or {}
        saved.sound = sound.checked
        saved.effects = effects.checked
        assert(love.filesystem.write("options_state.save", table.serialize(saved)))
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
    enter = enter,
    exit = state.unload_love
}
