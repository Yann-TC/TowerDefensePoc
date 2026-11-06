-- The pointer of every scene: a 1 px BoxCollider following the mouse. The
-- CollisionSystem tells what it touches: State.pointed, read by the buttons
-- (hover) and the level (selecting a tower).
--
-- The collisions are the ones of the last frame (the CollisionSystem runs
-- after the scripts): one frame late, which cannot be seen.
local State = require("state")
local Util = require("util")

local Pointer = {}

function Pointer:update(dt)
    State.pointed = getCollisions(self.entity)
    local mouse = input.getMousePosition()
    State.pointer.x, State.pointer.y = mouse.x, mouse.y
    Util.moveTo(self.entity, mouse.x, mouse.y)
end

return Pointer
