-- Per level: cost (build or upgrade), damage, range (pixels), rate (shots per
-- second), splash (radius around the impact).
local TowerKinds = {
    sellRatio = 0.7,
    order = { "gun", "cannon", "rocket", "missile" },
    gun = {
        name = "Gun", prefab = "world/prefabs/towers/gun.json",
        projectile = "world/prefabs/projectiles/bullet.json",
        air = true, ground = true, turn = 540, muzzle = 28, flash = true,
        levels = {
            { cost = 60, damage = 6, range = 150, rate = 3 },
            { cost = 50, damage = 10, range = 165, rate = 3.5 },
            { cost = 90, damage = 15, range = 180, rate = 4.5 },
        },
    },
    cannon = {
        name = "Cannon", prefab = "world/prefabs/towers/cannon.json",
        projectile = "world/prefabs/projectiles/shell.json",
        air = false, ground = true, turn = 220, muzzle = 26, flash = true,
        levels = {
            { cost = 90, damage = 24, range = 140, rate = 0.8, splash = 55 },
            { cost = 70, damage = 38, range = 150, rate = 0.85, splash = 60 },
            { cost = 120, damage = 60, range = 165, rate = 0.95, splash = 70 },
        },
    },
    rocket = {
        name = "Rocket", prefab = "world/prefabs/towers/rocket.json",
        projectile = "world/prefabs/projectiles/rocket.json",
        air = true, ground = true, turn = 260, muzzle = 16, flash = false,
        levels = {
            { cost = 120, damage = 34, range = 190, rate = 0.7, splash = 45 },
            { cost = 90, damage = 48, range = 200, rate = 0.9, splash = 50 },
            { cost = 150, damage = 70, range = 215, rate = 1.1, splash = 55 },
        },
    },
    missile = {
        name = "Missile", prefab = "world/prefabs/towers/missile.json",
        projectile = "world/prefabs/projectiles/missile.json",
        air = true, ground = false, turn = 300, muzzle = 14, flash = false,
        levels = {
            { cost = 110, damage = 45, range = 250, rate = 0.9 },
            { cost = 90, damage = 70, range = 270, rate = 1.0 },
            { cost = 140, damage = 110, range = 290, rate = 1.25 },
        },
    },
}

return TowerKinds
