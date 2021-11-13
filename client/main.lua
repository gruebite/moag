
local suit = require("lib.suit")

local resources = require(..., "resources")
local state = require(..., "state")

function love.load(args)
    love.keyboard.setKeyRepeat(true)

    resources:load("small_font", "fonts/Nouveau_IBM.ttf", 12)
    resources:load("medium_font", "fonts/Nouveau_IBM.ttf", 16)
    resources:load("large_font", "fonts/Nouveau_IBM.ttf", 24)

    resources:load("bullet", "images/bullet.png")
    resources:load("crate", "images/crate.png")
    resources:load("rover", "images/rover.png")
    resources:load("turret", "images/turret.png")

    resources:load("explosion", "images/explosion.png")

    resources:load("backdrop", "images/backdrop.png")

    resources:load("boom", "sounds/boom.wav", "static")

    suit.theme.color = {
        normal = { bg = { 0.125, 0.125, 0.125 }, fg = { 0.75, 0.75, 0.75 } },
        hovered = { bg = { 0.5, 0.5, 0.5 }, fg = { 0.75, 0.75, 0.75 } },
        active = { bg = { 0.5, 0.5, 0.5 }, fg = { 1, 1, 1 } }
    }

    state.switch("client.main_state", args)
end
