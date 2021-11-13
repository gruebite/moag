
local Vec2 = require("shared.Vec2")

local resources = require(..., "resources")

local Chatbox = {}
Chatbox.__index = Chatbox

Chatbox.EXPIRE_SECS = 10
Chatbox.MAX_LINES = 10
Chatbox.LINE_HEIGHT = 15

function Chatbox.new()
    return setmetatable({
        lines = {},
        text = ""
    }, Chatbox)
end

function Chatbox:add_line(text)
    self.lines[#self.lines + 1] = {
        sprite = love.graphics.newText(resources:get("small_font"), text),
        expires_at = love.timer.getTime() + Chatbox.EXPIRE_SECS
    }
    if #self.lines == Chatbox.MAX_LINES then
        table.remove(self.lines, 1)
    end
end

function Chatbox:enter()
    self.entering = true
end

function Chatbox:update(dt)
    for i = #self.lines, 1, -1 do
        if self.lines[i].expires_at <= love.timer.getTime() then
            table.remove(self.lines, i)
        end
    end
end

function Chatbox:draw()
    love.graphics.setColor(1, 1, 1, 1)
    local x = 5
    for i, line in ipairs(self.lines) do
        local y = (i - 1) * Chatbox.LINE_HEIGHT
        love.graphics.draw(line.sprite, x, y)
    end
end

return Chatbox
