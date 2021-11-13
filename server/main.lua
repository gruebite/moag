local conf = require("conf")

local nata = require("lib.nata")

local Vec2 = require("shared.Vec2")
local Terrain = require("shared.Terrain")
local UpkeepSystem = require("shared.systems.UpkeepSystem")
local ExplosionSystem = require("shared.systems.ExplosionSystem")
local LoggingSystem = require("shared.systems.LoggingSystem")

local CollisionSystem = require(..., "systems.CollisionSystem")
local ScoreSystem = require(..., "systems.ScoreSystem")
local WeatherSystem = require(..., "systems.WeatherSystem")
local LifetimeSystem = require(..., "systems.LifetimeSystem")
local DestroyedSystem = require(..., "systems.DestroyedSystem")
local CrateSpawnSystem = require(..., "systems.CrateSpawnSystem")
local NotifySystem = require(..., "systems.NotifySystem")
local PhysicsSystem = require(..., "systems.PhysicsSystem")
local RespawnSystem = require(..., "systems.RespawnSystem")
local ServerSystem = require(..., "systems.ServerSystem")

-- terrain delegate
local function terrain_grid(w, h)
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
        self._cells[(pos.y - 1) * w + pos.x] = to
    end
    function self:get_at(pos)
        return self._cells[(pos.y - 1) * w + pos.x]
    end
    function self:get_all()
        return self._cells
    end
    self._cells = {}
    for i = 1, w * h do
        table.insert(self._cells, Terrain.AIR)
    end
    return self
end

local pool

function love.load(args)
    math.randomseed(os.time())
    local terra = Terrain.new(terrain_grid(conf.WIDTH, conf.HEIGHT))
    terra:set_rect(Vec2.new(1, 1), Vec2.new(conf.WIDTH, conf.HEIGHT), Terrain.AIR)
    terra:set_rect(Vec2.new(1, conf.HEIGHT / 3.0), Vec2.new(conf.WIDTH, conf.HEIGHT), Terrain.DIRT)

    pool = nata.new({
        groups = {
            network = {filter = {"network"}},
            explosion = {filter = {"pos", "explosion"}},
            render = {filter = {"pos", "render"}},
            physics = {filter = {"pos", "vel", "siz", "physics"}},
            respawn = {filter = {"respawn"}},
            lifetime = {filter = {"lifetime"}}
        },
        systems = {
            -- Event based.
            --LoggingSystem,
            NotifySystem,
            ExplosionSystem,
            CollisionSystem,
            ScoreSystem,
            DestroyedSystem,

            -- Update (and some events) based.
            UpkeepSystem,
            LifetimeSystem,
            WeatherSystem,
            CrateSpawnSystem,
            PhysicsSystem,
            RespawnSystem,
            ServerSystem,
        }
    }, {
        terra = terra,
        port = conf.PORT
    })
end

function love.update(dt)
    pool:flush()
    pool:emit("update", dt)
    pool:remove(function(entity)
        return entity.destroyed
    end)
end
