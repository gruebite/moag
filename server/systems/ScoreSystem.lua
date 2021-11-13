--[[
ScoreSystem handles updating scores on entity deaths and updating network
deltas.
--]]

local entity_factory = require("shared.entity_factory")

local ScoreSystem = {}

local THRESHOLDS = {
    [5] = 10,
    [10] = 20,
    [20] = 50,
    [50] = 100,
    [100] = math.huge
}

local STREAKS = {
    [3] = "cluster bomb",
    [5] = "baby nuke",
    [10] = "mirv",
}

function ScoreSystem:init(args)
    self._threshold = 5
end

-- EVENTS

function ScoreSystem:entity_killed(tar, src)
    if tar == src and tar.score then
        if tar.nick then
            self.pool:emit("notify", ("* %s had an accident"):format(tar.nick))
        end
        tar.score.suicides = (tar.score.suicides or 0) + 1
        tar.score.streak = 0
        if tar.network then
            tar.network.deltas["score.suicides"] = true
        end
    else
        if tar.nick and src.nick then
            self.pool:emit("notify", ("* %s was killed by %s"):format(tar.nick, src.nick))
        end
        if tar.score then
            tar.score.deaths = (tar.score.deaths or 0) + 1
            tar.score.streak = 0
            if tar.network then
                tar.network.deltas["score.deaths"] = true
            end
        end
        if src.score then
            src.score.kills = (src.score.kills or 0) + 1
            src.score.streak = (src.score.streak or 0) + 1
            if src.network then
                src.network.deltas["score.kills"] = true
            end

            if STREAKS[src.score.streak] and src.nick and src.rover then
                local award = STREAKS[src.score.streak]
                src.rover.main_bullet = award
                if src.network then
                    src.network.deltas["rover.main_bullet"] = true
                end
                self.pool:emit("notify", "* " .. src.nick .. " is on a kill streak of " .. src.score.streak .. " and now has " .. award .. " as main weapon!")
            end

            if src.score.kills - src.score.suicides >= self._threshold and src.nick then
                self.pool:emit("notify", "* " .. src.nick .. " is the first to reach a score of " .. self._threshold .. "!")
                self._threshold = THRESHOLDS[self._threshold]
            end
        end
    end
end

return ScoreSystem