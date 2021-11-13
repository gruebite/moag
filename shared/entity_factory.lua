local conf = require("conf")

local ColorKind = require(..., "ColorKind")
local ExplosionKind = require(..., "ExplosionKind")
local Set = require(..., "Set")
local Vec2 = require(..., "Vec2")
local Terrain = require(..., "Terrain")

local M = {}

local bullet_types = {
    "baby nuke",
    "nuke",
    "bouncer",
    "cluster bomb",
    "cluster bouncer",
    "tunneler",
    "mirv",
    "shotgun",

    "dirt",
    "super dirt",
    "collapse",
    "liquid dirt",
    
    -- Not in crates.
    "safe missile",
    "missile",
    "pellet",
    "warhead",
    "safe warhead",

    "dust",
    "meteorite",
}

-- Guide: <10 very rare, <30 rare, <60 uncommon, <100 common, <200 very common

local bullet_probs = {
    crate = {
        {"baby nuke", 60},
        {"nuke", 10},
        {"bouncer", 120},
        {"cluster bomb", 80},
        {"cluster bouncer", 15},
        {"tunneler", 75},
        {"mirv", 30},
        {"shotgun", 140},

        {"dirt", 100},
        {"super dirt", 40},
        {"collapse", 60},
        {"liquid dirt", 60},
    },
}

local iota = (function()
    -- Lower IDs are re-used and reserved for clients.
    local i = 99
    return function()
        i = i + 1
        return i
    end
end)()

-- Duplicated in WeatherSystem
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

function M.get_random_bullet(flavor)
    flavor = flavor or "crate"

    return random_weight(bullet_probs[flavor])
end

function M.player(id)
    return {
        nick = "p" .. id,
        color = ColorKind.WHITE,
        pos = Vec2.new(math.random(30, conf.WIDTH - 30), 30),
        siz = Vec2.new(conf.ROVER.WIDTH, conf.ROVER.HEIGHT),
        vel = Vec2.new(0, 0),
        offset = Vec2.new(0.5, 1),
        render = {
            sprite = "rover",
            children = {
                turret = {
                    pos = Vec2.new(0, -conf.ROVER.HEIGHT),
                    siz = Vec2.new(conf.TURRET.WIDTH, conf.TURRET.HEIGHT),
                    offset = Vec2.new(0, 0.5),
                    rotation = 225,
                    sprite = "turret",
                }
            }
        },
        physics = {
            can_climb = true,
            oob_flags = {"collides", "collides", "collides"},
            collision_mask = Set.new({ "rover" })
        },
        rover = {
            turret_angle = 225,
            facingleft = true,
            speed = 60,
            boost_speed = 100,
            main_bullet = "missile",
            special_bullet = "missile",
            special_ammo = 0,
            powerups = Set.new({ "" })
        },
        player = {
        },
        respawn = {},
        score = {
            kills = 0,
            deaths = 0,
            suicides = 0,
        },
        network = {
            snapshot = {
                ["nick"] = true,
                ["color"] = true,
                ["pos"] = true,
                ["dead"] = true,
                ["rover.turret_angle"] = true,
                ["rover.facingleft"] = true,
                ["rover.main_bullet"] = true,
                ["rover.special_bullet"] = true,
                ["rover.special_ammo"] = true,
                ["score.kills"] = true,
                ["score.deaths"] = true,
                ["score.suicides"] = true,
            },
            deltas = {},
            id = id
        },
        interpolation = {}
    }
end

function M.crate()
    return {
        pos = Vec2.new(math.random(30, conf.WIDTH - 30), 30),
        siz = Vec2.new(conf.CRATE.WIDTH, conf.CRATE.HEIGHT),
        vel = Vec2.new(0, 0),
        offset = Vec2.new(0.5, 1),
        render = {
            sprite = "crate"
        },
        physics = {
            oob_flags = {"collides", "collides", "collides"},
            collides_with = Set.new({ "rover", "bullet", "explosion" }),
            collision_mask = Set.new({ "crate" })
        },
        crate = {
            ammo = 1,
            bullet = M.get_random_bullet(),
        },
        network = {
            snapshot = {
                ["pos"] = true
            },
            deltas = {},
            id = iota()
        },
        interpolation = {}
    }
end

function M.bullet(kind, pos, vel, owner)
    local b = {
        pos = pos:cpy(),
        siz = Vec2.new(conf.BULLET.WIDTH, conf.BULLET.HEIGHT),
        vel = vel:cpy(),
        offset = Vec2.new(0.5, 0.5),
        render = {
            sprite = "bullet"
        },
        physics = {
            oob_flags = {"destructs", "exists", "collides"},
            collides_with = Set.new({ "rover" }),
            collision_mask = Set.new({ "bullet" })
        },
        bullet = {
            owner = owner,
            explosion_amount = 0,
            explosion_radius = 0,
            explosion_fill = Terrain.AIR,
            safe = false,
            health = 1,
        },
        network = {
            snapshot = {
                ["pos"] = true,
            },
            deltas = {},
            id = iota()
        },
        interpolation = {}
    }
    if kind == "safe missile" then
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
        b.bullet.safe = true
    elseif kind == "safe warhead" then
        b.bullet.explosion_radius = 30
        b.bullet.explosion_fill = Terrain.AIR
        b.bullet.safe = true
    elseif kind == "baby nuke" then
        b.bullet.explosion_radius = 55
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "nuke" then
        b.bullet.explosion_radius = 150
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "dirt" then
        b.bullet.explosion_radius = 55
        b.bullet.explosion_fill = Terrain.DIRT
        b.bullet.safe = true
    elseif kind == "super dirt" then
        b.bullet.explosion_radius = 300
        b.bullet.explosion_fill = Terrain.DIRT
        b.bullet.safe = true
    elseif kind == "collapse" then
        b.bullet.explosion_kind = ExplosionKind.COLLAPSE
        b.bullet.explosion_radius = 120
        b.bullet.safe = true
    elseif kind == "liquid dirt" then
        b.bullet.explosion_kind = ExplosionKind.LIQUID
        b.bullet.explosion_amount = 2000
        b.bullet.safe = true
    elseif kind == "bouncer" then
        b.physics.oob_flags[1] = "wraps"
        b.physics.bounces = true
        b.bullet.health = 11
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "cluster bomb" then
        b.bullet.explosion_radius = 20
        b.bullet.explosion_fill = Terrain.AIR
        b.bullet.cluster = "missile"
        b.bullet.cluster_count = 11
    elseif kind == "cluster bouncer" then
        b.bullet.explosion_radius = 20
        b.bullet.explosion_fill = Terrain.AIR
        b.bullet.cluster = "bouncer"
        b.bullet.cluster_count = 7
    elseif kind == "tunneler" then
        b.physics.ghost = true
        b.bullet.health = 20
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "mirv" then
        b.physics.destroyed_when_falling = true
        b.when_destroyed = {
            spawns = {
                M.bullet("warhead", Vec2.new(0, 0), Vec2.new(1.3, 0), owner),
                M.bullet("warhead", Vec2.new(0, 0), Vec2.new(1.0, 0), owner),
                M.bullet("warhead", Vec2.new(0, 0), Vec2.new(0.7, 0), owner),
                M.bullet("warhead", Vec2.new(0, 0), Vec2.new(0.4, 0), owner),
                M.bullet("warhead", Vec2.new(0, 0), Vec2.new(0.1, 0), owner),
            }
        }
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "shotgun" then
        b.lifetime = 0.01
        b.when_destroyed = {
            spawns = {
                M.bullet("pellet", Vec2.new(0, 0), Vec2.random_spread(0, math.pi / 8, 10), owner),
                M.bullet("pellet", Vec2.new(0, 0), Vec2.random_spread(0, math.pi / 8, 10), owner),
                M.bullet("pellet", Vec2.new(0, 0), Vec2.random_spread(0, math.pi / 8, 10), owner),
                M.bullet("pellet", Vec2.new(0, 0), Vec2.random_spread(0, math.pi / 8, 10), owner),
                M.bullet("pellet", Vec2.new(0, 0), Vec2.random_spread(0, math.pi / 8, 10), owner),
            }
        }
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "missile" then
        b.bullet.explosion_radius = 12
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "pellet" then
        b.bullet.explosion_radius = 6
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "warhead" then
        b.bullet.explosion_radius = 30
        b.bullet.explosion_fill = Terrain.AIR
    elseif kind == "dust" then
        b.physics.ignores_gravity = true
        b.bullet.explosion_radius = 2
        b.bullet.explosion_fill = Terrain.DIRT
        b.bullet.safe = true
    elseif kind == "meteorite" then
        b.physics.ignores_gravity = true
        b.bullet.explosion_radius = 6
        b.bullet.explosion_fill = Terrain.AIR
    end
    return b
end

function M.explosion(ent)
    ent = ent or M.bullet("missile", Vec2.new(), Vec2.new())
    return {
        pos = ent.pos:cpy(),
        siz = Vec2.new(ent.bullet.explosion_radius, ent.bullet.explosion_radius),
        -- necessary for physics (todo: does this need to be required?)
        vel = Vec2.new(0, 0),
        offset = Vec2.new(0.5, 0.5),
        explosion = {
            safe = ent.bullet.safe,
            owner = ent.bullet.owner,
            radius = ent.bullet.explosion_radius,
            fill = ent.bullet.explosion_fill,
            kind = ent.bullet.explosion_kind or 1,
            amount = ent.bullet.explosion_amount
        },
        lifetime = conf.SERVER_GAME_RATE + 0.1,
        physics = {
            ignores_velocity = true,
            ignores_gravity = true,
            collision_shape = "circle",
            collides_with = Set.new({ "rover" }),
            collision_mask = Set.new({ "explosion" })
        },
        network = {
            snapshot = {
                ["pos"] = true,
                ["explosion.radius"] = true,
                ["explosion.fill"] = true,
                ["explosion.kind"] = true,
                ["explosion.amount"] = true,
            },
            deltas = {},
            id = iota()
        }
    }
end

return M
