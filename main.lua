--[[
Main entry point. Sets up a few global conveniences and then calls the
server or client entry point.

TODO
* Split up bullets more. Health component should dictate bounces and tunnels.
* Move some things to client side like turret positioning.
* Add fire cooldown on server.

--]]

-- Relative require.
local oldrequire = require
function require(this, path)
    if not path then
        return oldrequire(this)
    else
        return oldrequire(this:match("(.-)[^%.]+$") .. path)
    end
end

local conf = require("conf")

local bitser = require("lib.bitser")

function table.serialize(tab)
    return bitser.dumps(tab)
end

function table.deserialize(str)
    return bitser.loads(str)
end

function table.deepcopy(t, into)
    into = into or {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            into[k] = into[k] or {}
            table.deepcopy(v, into[k])
        else
            into[k] = v
        end
    end
    return into
end

local saved, _ = love.filesystem.read("options_state.save")

if saved then
    saved = table.deserialize(saved)
    conf.PLAY_SOUND = saved.sound
    conf.EFFECTS = saved.effects
end


if conf.IS_SERVER then
    require("server.main")
else
    require("client.main")
end
