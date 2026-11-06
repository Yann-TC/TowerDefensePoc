-- Debug view of the physics, shown or hidden with C: the bounds of every
-- BoxCollider (getColliders, getBounds), red when the CollisionSystem found
-- it touching another one (getCollisions), green otherwise. Its Props:
--   shown  whether it is shown when the scene starts
--
-- Each bounds is drawn by an outlined Rectangle, created when needed and
-- kept for the next frames: the extra ones are hidden.
local Util = require("util")

local Colliders = {}

local BOX = "world/prefabs/ui/colliderBox.json"

function Colliders:start(dt)
    self.shown = getProps(self.entity).shown == true
    self.boxes = {}
end

function Colliders:update(dt)
    if input.getButtonDown("Colliders") then
        self.shown = not self.shown
    end
    local colliders = self.shown and getColliders() or {}
    for i, collider in ipairs(colliders) do
        self:draw(self:box(i), collider)
    end
    for i = #colliders + 1, #self.boxes do
        Util.setShown(self.boxes[i], false)
    end
end

-- The i-th Rectangle, created the first time it is needed.
function Colliders:box(i)
    if not self.boxes[i] then
        self.boxes[i] = instantiate(BOX)
    end
    return self.boxes[i]
end

function Colliders:draw(box, collider)
    local bounds = getBounds(collider)
    Util.moveTo(box, bounds.x, bounds.y)
    local rectangle = getRectangle(box)
    rectangle.size.x, rectangle.size.y = bounds.width, bounds.height
    if #getCollisions(collider) > 0 then
        Util.setColor(rectangle.outline, 240, 70, 70, 230)
    else
        Util.setColor(rectangle.outline, 90, 230, 90, 230)
    end
end

return Colliders
