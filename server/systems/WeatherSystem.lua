
local conf = require("conf")

local Vec2 = require("shared.Vec2")
local entity_factory = require("shared.entity_factory")
local Timer = require("shared.Timer")

local WEATHER_COOLDOWN = 300
local WEATHER_LENGTH = 60

local WEATHER_EVENTS = {
    {"dust storm", 30},
    {"meteor shower", 60},
}

local function random_weight(choices)
    local total = 0
    for _, p in ipairs(choices) do
        total = total + p[2]
    end
    local r = math.random(1, total)
    for i, p in ipairs(choices) do
        r = r - p[2]
        if r <= 0 then
            return choices[i][1]
        end
    end
    error("bug")
end

local WeatherSystem = {}

function WeatherSystem:init(args)
    self.cooldown = Timer.cooldown(math.random(1, WEATHER_COOLDOWN))
    self.cooldown:reset() -- A cooldown is true by default, this ensures not.
    self.length = Timer.countdown(0)
    self.current = nil
end

WeatherSystem["dust storm"] = function(self, dt)
    if not self.started then
        self.started = true
        --self.amp = math.random() + 0.5
        self.period = math.random() * math.pi * 2 + math.pi
        self.shift = math.random() * math.pi * 2
        --self.vert = math.random()
        self.accum = 0
        self.pulse = Timer.pulse(0.1)
    end

    self.accum = self.accum + dt
    self.intensity = --[[self.amp *]] math.sin(self.period * (self.accum + self.shift)) --[[+ self.vert]]

    if not self.pulse:tick(dt) then
        return
    end

    if math.random() < self.intensity then
        self.pool:queue(entity_factory.bullet(
            "dust",
            Vec2.new(math.random(30, conf.WIDTH - 30), 1),
            Vec2.new(math.random(-10, 10), 40),
            "a dust particle"
        ))
    end
end

WeatherSystem["meteor shower"] = function(self, dt)
    if not self.started then
        self.started = true
        self.amp = math.random() * 0.2
        self.period = math.random() * math.pi * 2 + math.pi
        self.shift = math.random() * math.pi * 2
        --self.vert = math.random()
        self.accum = 0
        self.pulse = Timer.pulse(0.1)
    end

    self.accum = self.accum + dt
    self.intensity = self.amp * math.sin(self.period * (self.accum + self.shift)) --[[+ self.vert]]

    if not self.pulse:tick(dt) then
        return
    end

    if math.random() < self.intensity then
        self.pool:queue(entity_factory.bullet(
            "meteorite",
            Vec2.new(math.random(30, conf.WIDTH - 30), 1),
            Vec2.new(math.random(-40, 40), 80),
            "a meteorite"
        ))
    end
end

-- EVENTS

function WeatherSystem:update(dt)
    if self.current then
        if not self.length:tick(dt) then
            self.pool:emit("notify", "* the " .. self.current .. " has ended!")
            self.current = nil
            self.cooldown:reset(math.random(1, WEATHER_COOLDOWN))
            self.started = nil
        else
            self[self.current](self, dt)
        end
        return
    end

    if self.cooldown:tick(dt) then
        self.current = random_weight(WEATHER_EVENTS)
        self.length:reset(math.random(1, WEATHER_LENGTH))
        self.pool:emit("notify", "* a " .. self.current .. " has begun!")
    end
end

return WeatherSystem