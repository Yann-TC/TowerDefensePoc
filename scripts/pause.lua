local State = require("state")
local Util = require("util")

local Pause = {}

function Pause:update(dt)
    Util.setShown(self.entity, State.game.paused)
end

return Pause
