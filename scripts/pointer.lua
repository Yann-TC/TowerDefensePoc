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
