-- Short-lived effects created by the gameplay (see effect.lua for how they
-- live): popups, explosions, debris, and the spawn that survives a full
-- World.
local State = require("state")
local Util = require("util")

local Fx = {}

local MAX_BOOMS = 4 -- Explosions heard per frame, the others are silent
local DEBRIS_SPREAD, DEBRIS_LIFT = 110, 320 -- Pixels per second

-- Util.spawnAt, but returns nil instead of raising an error when the prefab
-- cannot be created (the World is full): the failure is counted.
function Fx.trySpawn(prefab, x, y)
    local ok, entity = pcall(Util.spawnAt, prefab, x, y)
    if ok then
        return entity
    end
    State.addMetric("game.spawnsRefused", 1)
    return nil
end

-- Text going up from a point, like the gold won (gold color by default).
function Fx.popup(text, x, y, r, g, b)
    local entity = Fx.trySpawn("world/prefabs/fx/popup.json", x, y)
    if entity then
        local label = getText(entity)
        label.value = text
        Util.setColor(label.color, r or 255, g or 215, b or 64, 255)
    end
end

-- Pieces thrown up from (x, y): their Gravity brings them back down.
function Fx.debris(x, y, count)
    for _ = 1, count do
        local piece = Fx.trySpawn("world/prefabs/fx/debris.json", x, y)
        if piece then
            local velocity = getVelocity(piece).value
            velocity.x = (math.random() * 2 - 1) * DEBRIS_SPREAD
            velocity.y = -DEBRIS_LIFT * (0.6 + math.random() * 0.4)
        end
    end
end

-- An explosion with its sound, and a scorch mark left on the ground. Only a
-- few are heard each frame (map.lua resets the count), so a big wave does
-- not start hundreds of sounds at once; only these throw debris.
function Fx.explode(x, y, size, big)
    local prefab = big and "explosionBig" or "explosion"
    if State.booms >= MAX_BOOMS then
        prefab = "explosionQuiet"
    else
        Fx.debris(x, y, big and 8 or 4)
    end
    State.booms = State.booms + 1
    local blast = Fx.trySpawn("world/prefabs/fx/" .. prefab .. ".json", x, y)
    if blast then
        Util.setScale(blast, size)
    end
    local scorch = Fx.trySpawn("world/prefabs/fx/scorch.json", x, y)
    if scorch then
        Util.setRotation(scorch, math.random(0, 359))
    end
end

return Fx
