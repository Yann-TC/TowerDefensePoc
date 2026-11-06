-- The pause screen: shown while the game is paused, with its buttons.
local State = require("state")
local Util = require("util")

local Pause = {}

function Pause:update(dt)
    Util.setShown(self.entity, State.game.paused)
end

return Pause
