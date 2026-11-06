-- Helpers on top of the engine bindings: math, entities, interface. No game
-- state here.
local Util = {
    MAP_WIDTH = 1088, -- The panel of the HUD starts here
    HIDDEN = 100000,  -- Offset of the hidden entities, see setShown
}

---------------------------------------------------------------- math

function Util.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function Util.distance(ax, ay, bx, by)
    return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
end

-- Angle in degrees from a to b: 0 is to the right, 90 is down.
function Util.angleTo(ax, ay, bx, by)
    return math.deg(math.atan(by - ay, bx - ax))
end

-- Difference from one angle to another, between -180 and 180.
function Util.angleDelta(from, to)
    return (to - from + 180) % 360 - 180
end

-- Turns an angle toward another one, by at most step degrees.
function Util.turnToward(current, wanted, step)
    return current + Util.clamp(Util.angleDelta(current, wanted), -step, step)
end

---------------------------------------------------------------- entities

-- Creates a prefab with the engine's instantiate, its root moved by (x, y):
-- its children follow, their Transforms are relative to it.
function Util.spawnAt(prefab, x, y)
    local entity = instantiate(prefab)
    Util.moveBy(entity, x, y)
    return entity
end

-- Position of an entity relative to its parent: the world position for a
-- root entity (enemy, tower, projectile...).
function Util.position(entity)
    local p = getTransform(entity).position
    return p.x, p.y
end

function Util.setRotation(entity, degrees)
    getTransform(entity).rotationDegrees.z = degrees
end

function Util.setScale(entity, scale)
    local transform = getTransform(entity)
    transform.scale.x = scale
    transform.scale.y = scale
end

function Util.moveBy(entity, dx, dy)
    local p = getTransform(entity).position
    p.x = p.x + dx
    p.y = p.y + dy
end

function Util.moveTo(entity, x, y)
    local p = getTransform(entity).position
    p.x, p.y = x, y
end

function Util.setColor(color, r, g, b, a)
    color.r = math.floor(Util.clamp(r, 0, 255))
    color.g = math.floor(Util.clamp(g, 0, 255))
    color.b = math.floor(Util.clamp(b, 0, 255))
    color.a = math.floor(Util.clamp(a, 0, 255))
end

-- The color an entity is drawn with: its Sprite, Text or Circle.
function Util.mainColor(entity)
    if hasSprite(entity) then
        return getSprite(entity).color
    end
    if hasText(entity) then
        return getText(entity).color
    end
    return getCircle(entity).fill
end

function Util.setAlpha(entity, alpha)
    Util.mainColor(entity).a = math.floor(Util.clamp(alpha, 0, 255))
end

-- Hides an entity and its children by moving it far away, or brings it
-- back (the engine has no visibility flag). Works for every drawable.
function Util.setShown(entity, shown)
    local x = Util.position(entity)
    if shown and x > Util.HIDDEN / 2 then
        Util.moveBy(entity, -Util.HIDDEN, 0)
    elseif not shown and x < Util.HIDDEN / 2 then
        Util.moveBy(entity, Util.HIDDEN, 0)
    end
end

---------------------------------------------------------------- interface

-- Width of a text in pixels, close enough for the font of the game (the
-- engine does not give the size of a Text).
function Util.textWidth(value, size)
    local width = 0
    for char in value:gmatch(".") do
        if char:find("[ijlI%.,:;!|' ]") then
            width = width + 0.27
        elseif char:find("[frt%(%)%-/]") then
            width = width + 0.34
        elseif char:find("[MWmw]") then
            width = width + 0.83
        elseif char:find("%u") then
            width = width + 0.68
        else
            width = width + 0.54
        end
    end
    return width * size
end

-- Puts a text centered on x.
function Util.centerText(entity, x)
    local text = getText(entity)
    getTransform(entity).position.x = x - Util.textWidth(text.value, text.size) / 2
end

-- Leaves the scene; the time runs again if it was paused.
function Util.changeScene(name)
    getClock().timeScale = 1
    loadScene(name)
end

return Util
