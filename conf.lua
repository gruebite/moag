
local M = {
    -- Client and server.

    WIDTH = 1600,
    HEIGHT = 900,

    PORT = "6624",
    
    -- Hard-coded based on sprite sizes.
    BULLET = {
        WIDTH = 3,
        HEIGHT = 3
    },
    CRATE = {
        WIDTH = 9,
        HEIGHT = 9
    },
    ROVER = {
        WIDTH = 18,
        HEIGHT = 9
    },
    TURRET = {
        WIDTH = 9,
        HEIGHT = 3
    },

    -- Client.

    HOST = "localhost",
    CONNECT_TIMEOUT = 10, -- Seconds.

    INPUT_SAMPLE_RATE = 0.020, -- 50 per second, recommened by Source Engine.

    -- Options
    PLAY_SOUND = true,
    EFFECTS = true,

    -- Server.

    GRAVITY = 180,

    MIN_CRATE_SPAWN_TIME = 10, -- Seconds.
    MAX_CRATE_SPAWN_TIME = 30,

    -- How often the server sends snapshots.
    SERVER_SAMPLE_RATE = 0.050, -- 20 per second, recommended by Source Engine.
    -- How often the server updates physics.
    SERVER_GAME_RATE = 0.015, -- 66.6 per second, recommened by Source Engine.
}

local i = 2
while i <= #arg do
    if arg[i] == "--server" then
        M.IS_SERVER = true
    elseif arg[i] == "--host" then
        i = i + 1
        M.HOST = arg[i]
    elseif arg[i] == "--port" then
        i = i + 1
        M.PORT = arg[i]
    end
    i = i + 1
end

function love.conf(t)
    t.identity = "MOAG"
    t.version = "11.2"
    t.console = true
    t.accelerometerjoystick = true
    t.externalstorage = false
    t.gammacorrect = false

    if M.IS_SERVER then
        t.window = nil

        t.modules.audio = false
        t.modules.event = false
        t.modules.graphics = false
        t.modules.image = false
        t.modules.joystick = false
        t.modules.keyboard = false
        t.modules.math = false
        t.modules.mouse = false
        t.modules.physics = false
        t.modules.sound = false
        t.modules.system = false
        t.modules.timer = true
        t.modules.touch = false
        t.modules.video = false
        t.modules.window = false
        t.modules.thread = false
    else
        t.window.title = "MOAG"
        t.window.icon = "resources/images/rover.png"
        t.window.width = M.WIDTH
        t.window.height = M.HEIGHT
        t.window.borderless = false
        t.window.resizable = false
        t.window.minWIDTH = 1
        t.window.minHEIGHT = 1
        t.window.fullscreen = false
        t.window.fullscreentype = "desktop"
        t.window.vsync = true
        t.window.msaa = 0
        t.window.display = 1
        t.window.highdpi = false
        t.window.x = nil
        t.window.y = nil

        t.modules.audio = true
        t.modules.event = true
        t.modules.graphics = true
        t.modules.image = true
        t.modules.joystick = true
        t.modules.keyboard = true
        t.modules.math = true
        t.modules.mouse = true
        t.modules.physics = true
        t.modules.sound = true
        t.modules.system = true
        t.modules.timer = true
        t.modules.touch = true
        t.modules.video = true
        t.modules.window = true
        t.modules.thread = true
    end
end

return M
