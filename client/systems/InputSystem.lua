--[[
System to handle inputs from the user. It sends pulses to the server.
--]]
local conf = require("conf")

local bit_set = require("shared.bit_set")
local nentities = require("shared.nentities")
local Vec2 = require("shared.Vec2")
local InputKind = require("shared.InputKind")
local ChunkKind = require("shared.ChunkKind")
local Timer = require("shared.Timer")

local resources = require("client.resources")

local ClientSystem = require(..., "ClientSystem")

local lkb = love.keyboard

local InputSystem = {}

function InputSystem:init(args)
    self.input_timer = Timer.pulse(conf.INPUT_SAMPLE_RATE)
    -- Simulate button press.
    self.special_cooldown = Timer.cooldown(0.2)

    self.charging = nil
    self.fire_power = nil
    self.special = false

    self.input_state = 0

    -- Used to send to the server and know about "you" and turret angle.
    self.client_sys = self.pool:getSystem(ClientSystem)

    self.enabled = true
end

function InputSystem:enable(to)
    self.enabled = to
end

-- EVENTS

function InputSystem:update(dt)
    if not self.client_sys.you or not self.enabled then
        return
    end

    -- TODO keymappings
    if lkb.isDown("left") or lkb.isDown("a") then
        self.input_state = bit_set.on(self.input_state, InputKind.MOVE_LEFT)
    else
        self.input_state = bit_set.off(self.input_state, InputKind.MOVE_LEFT)
    end
    
    if lkb.isDown("right") or lkb.isDown("d") then
        self.input_state = bit_set.on(self.input_state, InputKind.MOVE_RIGHT)
    else
        self.input_state = bit_set.off(self.input_state, InputKind.MOVE_RIGHT)
    end

    local you = nentities:get(self.client_sys.you)
    
    if lkb.isDown("up") or lkb.isDown("w") then
        self.input_state = bit_set.on(self.input_state, InputKind.MOVE_UP)
    else
        self.input_state = bit_set.off(self.input_state, InputKind.MOVE_UP)
    end
    if lkb.isDown("down") or lkb.isDown("s") then
        self.input_state = bit_set.on(self.input_state, InputKind.MOVE_DOWN)
    else
        self.input_state = bit_set.off(self.input_state, InputKind.MOVE_DOWN)
    end

    if lkb.isDown("space") and not self.fire_power then
        self.charging = (self.charging or 0) + dt
    else
        if self.charging then
            self.fire_power = self.charging
        end
        self.charging = nil
    end

    if self.special_cooldown:tick(dt) and lkb.isDown("tab") then
        self.special_cooldown:reset()
        self.special = not self.special
    end

    if lkb.isDown("lshift") then
        -- This will be toggled off after we send it to the server.
        self.input_state = bit_set.on(self.input_state, InputKind.BOOST)
    end


    if not self.input_timer:tick(dt) then
        return
    end
    self.client_sys.peer:send(table.serialize {
        kind = ChunkKind.PLAYER_INPUT,
        state = self.input_state,
        fire = self.fire_power ~= nil,
        fire_power = self.fire_power or 0,
        special = self.special
    }, 0, "reliable")
    if self.fire_power then
        self.fire_power = nil
    end
    self.input_state = bit_set.off(self.input_state, InputKind.BOOST)
end

return InputSystem
