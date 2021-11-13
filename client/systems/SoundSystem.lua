

local conf = require("conf")

local Tween = require("lib.Tween")

local resources = require("client.resources")

local SoundSystem = {}

-- EVENTS

function SoundSystem:addToGroup(group, ent)
    if group == "explosion" then
        if conf.EFFECTS then
            self.pool:queue({
                pos = ent.pos,
                effects = {
                    radius = Tween.new(0.2, {value = 1}, {value = ent.explosion.radius}, "outQuad"),
                    alpha = Tween.new(0.2, {value = 1}, {value = 0.5}, "linear"),
                },
                render = {
                    sprite = (function()
                        local rs = {}
                        local r = 0
                        while r < math.pi * 2 do
                            local n = r + math.random() * math.pi / 4
                            rs[#rs + 1] = {r, n}
                            r = n + math.random() * math.pi / 4
                        end
                        return function(self)
                            love.graphics.setColor(1, 1, 1, self.effects.alpha.subject.value)
                            for _, r in ipairs(rs) do
                                love.graphics.arc("line", "open", self.pos.x, self.pos.y, self.effects.radius.subject.value, r[1], r[2])
                            end
                        end
                    end)()
                }
            })
        end

        if conf.PLAY_SOUND then
            love.audio.play(require("client.resources"):get("boom"))
        end
    end
end

return SoundSystem