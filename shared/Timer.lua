
local Timer = {}
Timer.__index = Timer

function Timer.cooldown(secs)
    return setmetatable({
        _secs = secs,
        _elapsed = secs,
        _kind = "cooldown"
    }, Timer)
end

function Timer.pulse(secs)
    return setmetatable({
        _secs = secs,
        _elapsed = 0,
        _kind = "pulse"
    }, Timer)
end

function Timer.countdown(secs)
    return setmetatable({
        _secs = secs,
        _elapsed = 0,
        _kind = "countdown"
    }, Timer)
end

function Timer:reset(secs)
    self._secs = secs or self._secs
    self._elapsed = 0
end

function Timer:kill()
    self._kind = "dead"
end

function Timer:_pulse()
    if self._elapsed >= self._secs then
        self._elapsed = self._elapsed - self._secs
        return true
    else
        return false
    end
end

function Timer:_cooldown()
    return self._elapsed >= self._secs
end

function Timer:_countdown()
    return self._elapsed < self._secs
end

function Timer:_dead()
    return false
end

function Timer:tick(dt)
    self._elapsed = self._elapsed + dt
    return self["_" .. self._kind](self)
end

return Timer