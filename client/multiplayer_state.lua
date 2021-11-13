--[[
Multiplayer menu.
--]]
local conf = require("conf")

local suit = require("lib.suit")

local ColorKind = require("shared.ColorKind")

local resources = require(..., "resources")
local state = require(..., "state")

local lg = love.graphics

local saved
local host_ip = { text = conf.HOST }
local host_port = { text = conf.PORT }
local nick = { text = "" }
local colors = {
    [ColorKind.WHITE] = { checked = false },
    [ColorKind.RED] = { checked = false },
    [ColorKind.GREEN] = { checked = false },
    [ColorKind.BLUE] = { checked = false },
    [ColorKind.YELLOW] = { checked = false },
    [ColorKind.MAGENTA] = { checked = false },
    [ColorKind.CYAN] = { checked = false },
}
local selected_color = ColorKind.WHITE
local selected = nil

local function draw_color(c)
    return function(checkbox, opt, x, y, w, h)
        if not checkbox.checked then
            love.graphics.setColor(c[1] * 0.3, c[2] * 0.3, c[3] * 0.3, c[4])
        else
            love.graphics.setColor(c)
        end
        love.graphics.rectangle("fill", x, y, w, h)
    end
end

local function enter(args)
    saved, _ = love.filesystem.read("multiplayer_state.save")
    if saved then
        saved = table.deserialize(saved)
        host_ip.text = saved.ip or host_ip.text
        host_port.text = saved.port or host_port.text
        nick.text = saved.nick or nick.text
        for _, c in ipairs(colors) do
            c.checked = false
        end
        if saved.color then
            colors[saved.color].checked = true
            selected_color = saved.color
        else
            colors[ColorKind.WHITE].checked = true
            selected_color = ColorKind.WHITE
        end
    end
end

function love.update(dt)
    local w = lg.getWidth()
    local h = lg.getHeight()
    suit.layout:reset(w * 0.3, h / 2)
    suit.layout:padding(0, 30)

    suit.layout:push(suit.layout:row(w * 0.4, 30))
    suit.Label("Host", { align = "left" }, suit.layout:row(w * 0.1, 30))
    if suit.Input(host_ip, suit.layout:col(w * 0.3, 30)).hit then
        selected = host_ip
    end
    suit.layout:pop()
    suit.layout:push(suit.layout:row(w * 0.4, 30))
    suit.Label("Port", { align = "left" }, suit.layout:col(w * 0.1, 30))
    if suit.Input(host_port, suit.layout:col(w * 0.3, 30)).hit then
        selected = host_post
    end
    suit.layout:pop()

    suit.layout:push(suit.layout:row(w * 0.4, 30))
    suit.Label("Nick", { align = "left" }, suit.layout:row(w * 0.1, 30))
    if suit.Input(nick, suit.layout:col(w * 0.3, 30)).hit then
        selected = nick
    end
    suit.layout:pop()
    suit.layout:push(suit.layout:row(w * 0.4, 30))
    suit.Label("Color", { align = "left" }, suit.layout:col(w * 0.1, 30))

    for c, v in pairs(colors) do
        local color = ColorKind.LOOKUP[c]
        if suit.Checkbox(v, { draw = draw_color(color) }, suit.layout:col(w * (0.3 / 7), 30)).hit then
            selected = v
            selected_color = c
            for cc, vv in pairs(colors) do
                if c ~= cc then
                    vv.checked = false
                end
            end
        end
    end
    suit.layout:pop()
    suit.layout:padding(20, 30)
    if suit.Button("Back", suit.layout:row(w * 0.2 - 10, 30)).hit then
        state.switch("client.main_state")
    end
    if suit.Button("Connect", suit.layout:col(w * 0.2 - 10, 30)).hit then
        saved = saved or {}
        saved.ip = host_ip.text
        saved.port = host_port.text
        saved.nick = nick.text
        saved.color = selected_color
        assert(love.filesystem.write("multiplayer_state.save", table.serialize(saved)))

        state.switch("client.connect_state", host_ip.text, host_port.text, nick.text, selected_color)
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
    if key == "return" then
        saved = saved or {}
        saved.ip = host_ip.text
        saved.port = host_port.text
        saved.nick = nick.text
        saved.color = selected_color
        assert(love.filesystem.write("multiplayer_state.save", table.serialize(saved)))

        state.switch("client.connect_state", host_ip.text, host_port.text, nick.text, selected_color)
    elseif key == "v" and love.keyboard.isDown("lctrl") then
        if selected then
            selected.text = love.system.getClipboardText()
        end
    else
        suit.keypressed(key)
    end
end

return {
    enter = enter,
    exit = state.unload_love
}
