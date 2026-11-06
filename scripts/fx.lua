local State = require("state")
local Util = require("util")

local Fx = {}

local MAX_HEARD_BOOMS = 4
local DEBRIS_SPREAD, DEBRIS_LIFT = 110, 320

-- nil instead of an error when the World is full.
function Fx.trySpawn(prefab, x, y)
    local ok, entity = pcall(Util.spawnAt, prefab, x, y)
    return ok and entity or nil
end

function Fx.popup(text, x, y, r, g, b)
    local entity = Fx.trySpawn("world/prefabs/fx/popup.json", x, y)
    if entity then
        local label = getText(entity)
        label.value = text
        Util.setColor(label.color, r or 255, g or 215, b or 64, 255)
    end
end

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

-- Past MAX_HEARD_BOOMS this frame (reset by map.lua), silent and without debris.
function Fx.explode(x, y, size, big)
    local prefab = big and "explosionBig" or "explosion"
    if State.booms >= MAX_HEARD_BOOMS then
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
