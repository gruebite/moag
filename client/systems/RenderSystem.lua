local conf = require("conf")

local Vec2 = require("shared.Vec2")

local resources = require("client.resources")

local RenderSystem = {}
RenderSystem.__index = RenderSystem

function RenderSystem:init(args)

    self.terra = args.terra
end

function RenderSystem:_render_entity(ent, ox, oy)
    ox = ox or 0
    oy = oy or 0
    if ent.render.sprite then
        -- we render sprites at bottom center
        local pos = Vec2.new(ent.pos.x + ox, ent.pos.y + oy)

        if ent.render.tint then
            love.graphics.setColor(unpack(ent.render.tint))
        else
            love.graphics.setColor(255, 255, 255, 255)
        end
        local sprite = ent.render.sprite
        if type(sprite) == "string" then
            sprite = resources:get(sprite)
            love.graphics.draw(
                    sprite,
                    math.floor(pos.x + 0.5), math.floor(pos.y + 0.5),
                    ent.rotation and math.rad(ent.rotation) or 0,
                    (ent.siz and ent.siz.x or sprite:getWidth()) / sprite:getWidth(),
                    (ent.siz and ent.siz.y or sprite:getHeight()) / sprite:getHeight(),
                    math.floor((ent.offset and ent.offset.x or 0) * (ent.siz and ent.siz.x or 0)),
                    math.floor((ent.offset and ent.offset.y or 0) * (ent.siz and ent.siz.y or 0)))
        else
            sprite(ent)
        end

        if ent.render.children then
            for _, child in pairs(ent.render.children) do
                love.graphics.draw(
                        type(child.sprite) == "string" and resources:get(child.sprite) or child.sprite(child),
                        math.floor(pos.x + child.pos.x + 0.5), math.floor(pos.y + child.pos.y + 0.5),
                        math.rad(child.rotation),
                        1, 1,
                        math.floor((child.offset and child.offset.x or 0) *
                                (child.siz and child.siz.x or 0) + 0.5),
                        math.floor((child.offset and child.offset.y or 0) *
                                (child.siz and child.siz.y or 0) + 0.5))
            end
        end

        if ent.nick then

            local ox = math.floor((ent.offset and ent.offset.x or 0) * (ent.siz and ent.siz.x or 0))
            local oy = math.floor((ent.offset and ent.offset.y or 0) * (ent.siz and ent.siz.y or 0))
            local f = resources:get("small_font")
            love.graphics.setFont(f)
            local w = f:getWidth(ent.nick)
            local h = f:getHeight(ent.nick)
            love.graphics.print(
                    ent.nick,
                    ent.pos.x, ent.pos.y - (oy * 3), 0, 1, 1,
                    w / 2, h / 2)--w / 2, h / 2)
        end
    else
        love.graphics.draw(ent:get_drawable())
    end
end

-- EVENTS

function RenderSystem:render()
    love.graphics.setColor(255, 255, 255, 255)
    local bd = resources:get("backdrop")
    love.graphics.draw(bd, 0, 0, 0, love.graphics.getWidth() / bd:getWidth(), love.graphics.getHeight() / bd:getHeight())
    love.graphics.draw(self.terra.delegate:get_drawable())

    for _, ent in ipairs(self.pool.groups.render.entities) do
        if not ent.dead then
            self:_render_entity(ent)
        end
    end
end

return RenderSystem
