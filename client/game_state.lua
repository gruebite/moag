local conf = require("conf")
local utf8 = require("utf8")

local suit = require("lib.suit")
local nata = require("lib.nata")

local ColorKind = require("shared.ColorKind")
local Vec2 = require("shared.Vec2")
local nentities = require("shared.nentities")
local Terrain = require("shared.Terrain")

local LoggingSystem = require("shared.systems.LoggingSystem")
local ExplosionSystem = require("shared.systems.ExplosionSystem")

local ClientSystem = require(..., "systems.ClientSystem")
local InputSystem = require(..., "systems.InputSystem")
local InterpolationSystem = require(..., "systems.InterpolationSystem")
local EffectsSystem = require(..., "systems.EffectsSystem")
local SoundSystem = require(..., "systems.SoundSystem")
local RenderSystem = require(..., "systems.RenderSystem")
local resources = require(..., "resources")
local state = require(..., "state")
local Chatbox = require(..., "Chatbox")

local pool
local terra
local client
local input

local chatbox

local entering_text = false
local text = ""

local show_scoreboard = false
local fullscreen = false
local scale_x, scale_y = 1, 1

-- Terrain delegate

local color_lookup = {
    [Terrain.AIR] = { 0, 0, 0, 0 },
    [Terrain.DIRT] = { 0.5, 0.5, 0.5, 1 }
}
local terrain_lookup = {
    ["0.0,0.0,0.0,0.0"] = Terrain.AIR,
    ["0.5,0.5,0.5,1.0"] = Terrain.DIRT
}

local function terrain_image(w, h)
    local self = {}
    function self:get_width()
        return w
    end
    function self:get_height()
        return h
    end
    function self:in_bounds(v)
        return v.x >= 1 and v.y >= 1 and v.x <= w and v.y <= h
    end
    function self:set_at(pos, to)
        local c = color_lookup[to]
        self.dirty = true
        self.imagedata:setPixel(pos.x - 1, pos.y - 1, c[1], c[2], c[3], c[4])
    end
    function self:get_at(pos)
        local r, g, b, a = self.imagedata:getPixel(pos.x - 1, pos.y - 1)
        self.dirty = true
        local sf = function(f)
            return string.format("%.1f", f)
        end
        return terrain_lookup[sf(r) .. "," .. sf(g) .. "," .. sf(b) .. "," .. sf(a)]
    end
    function self:get_drawable()
        if self.dirty then
            self.image:replacePixels(self.imagedata)
            self.dirty = false
        end
        return self.image, 0, 0
    end
    self.dirty = false
    self.imagedata = love.image.newImageData(w, h)
    self.image = love.graphics.newImage(self.imagedata)
    return self
end

local function enter(batch, host, peer)

    scale_x = love.graphics.getWidth() / conf.WIDTH
    scale_y = love.graphics.getHeight() / conf.HEIGHT

    local terra = Terrain.new(terrain_image(
            love.graphics.getWidth(), love.graphics.getHeight()))
    terra:set_rect(Vec2.new(1, 1), Vec2.new(
        love.graphics.getWidth(), love.graphics.getHeight()), Terrain.AIR)

    pool = nata.new({
        groups = {
            network = {filter = {"network"}},
            explosion = {filter = {"pos", "explosion"}},
            render = {filter = {"pos", "render"}},
            score = {filter = {"score"}},
            interpolation = {filter = {"pos", "interpolation"}},

            effects = {filter = {"pos", "effects", "render"}}
        },
        systems = {
            --LoggingSystem,
            ClientSystem,
            InterpolationSystem, -- Goes after client, before rendering.
            ExplosionSystem,
            InputSystem,
            EffectsSystem,
            SoundSystem,
            RenderSystem,
        }
    }, {
        terra = terra,
        chatbox = Chatbox.new(),
        host = host,
        peer = peer,
    })

    client = pool:getSystem(ClientSystem)
    input = pool:getSystem(InputSystem)

    chatbox = pool:getSystem(ClientSystem).chatbox

    pool:on("disconnected", function()
        state.switch("client.disconnected_state")
    end)

    for _, c in ipairs(batch) do
        client:process_chunk(c)
    end
end

function love.draw()
    love.graphics.setFont(resources:get("small_font"))
    love.graphics.scale(scale_x, scale_y)
    pool:emit("render")

    if entering_text then
        local y = Chatbox.LINE_HEIGHT * Chatbox.MAX_LINES
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", 5, y, 5, 5)
        love.graphics.print(text, 15, y)
    end

    chatbox:draw()

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    local you = nentities:get(client.you)

    if you then
        love.graphics.setFont(resources:get("small_font"))
        if input.special then
            love.graphics.setColor(0.5, 0, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        if input.special and you.rover.special_ammo > 0 then
            love.graphics.print(you.rover.special_bullet .. " x" .. you.rover.special_ammo, 0, h - resources:get("small_font"):getHeight() * 2)
        else
            love.graphics.print(you.rover.main_bullet, 0, h - resources:get("small_font"):getHeight() * 2)
        end
    end

    love.graphics.setFont(resources:get("medium_font"))
    if show_scoreboard then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        love.graphics.setColor(0, 0, 0, 0.78)
        love.graphics.rectangle("fill", w * 0.10, h * 0.10, w * 0.8, h * 0.8)
        love.graphics.setColor(1, 1, 1, 0.78)
        love.graphics.rectangle("line", w * 0.10, h * 0.10, w * 0.8, h * 0.8)
        suit.draw()
    end
end

function love.update(dt)
    chatbox:update(dt)
    pool:flush()
    pool:remove(function(entity)
        return entity.destroyed
    end)
    pool:emit("update", dt)

    if show_scoreboard then

        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        suit.layout:reset(w * 0.1, h * 0.1)
        suit.layout:padding(0, 10)

        local title_font = resources:get("large_font")
        local row_font = resources:get("medium_font")
        suit.Label("Scores", {align = "center", font = title_font}, suit.layout:row(w * 0.8, title_font:getHeight()))

        suit.layout:push(suit.layout:row(w * 0.8, row_font:getHeight()))
        suit.Label("Name", {align = "center"}, suit.layout:row(w * 0.16, row_font:getHeight()))
        suit.Label("Kills (+1)", {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
        suit.Label("Deaths", {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
        suit.Label("Suicides (-1)", {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
        suit.Label("Score", {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
        suit.layout:pop()
        for _, ent in ipairs(pool.groups.score.entities) do
            suit.layout:push(suit.layout:row(w * 0.8, row_font:getHeight()))
            suit.Label(ent.nick, {align = "center", color = {normal = {fg = ColorKind.LOOKUP[ent.color]}}}, suit.layout:row(w * 0.16, row_font:getHeight()))
            suit.Label(ent.score.kills, {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
            suit.Label(ent.score.deaths, {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
            suit.Label(ent.score.suicides, {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))

            local score = ent.score.kills - ent.score.suicides
            suit.Label(score, {align = "center"}, suit.layout:col(w * 0.16, row_font:getHeight()))
            suit.layout:pop()
        end
    end
end

function love.textinput(t)
    if entering_text then
        text = text .. t
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(text, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            text = string.sub(text, 1, byteoffset - 1)
        end
    elseif key == "return" and love.keyboard.isDown("lalt") then
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen, "desktop")
    elseif key == "return" then
        if entering_text and text ~= "" then
            client:send_chat(text)
        end
        entering_text = not entering_text
        input:enable(not entering_text)
        text = ""
    elseif key == "escape" and entering_text then
        entering_text = false
        input:enable(not entering_text)
        text = ""
    elseif key == "escape" then
        show_scoreboard = not show_scoreboard
    end
end

function love.keyreleased(key)
end

function love.resize(w, h)
    scale_x = w / conf.WIDTH
    scale_y = h / conf.HEIGHT
end

return {
    enter = enter,
    exit = state.unload_love
}

