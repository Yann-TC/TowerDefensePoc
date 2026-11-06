-- A text of the HUD showing a value of the game. Its Props:
--   show  gold, lives or wave
local State = require("state")

local Label = {}

local FORMATS = {
    gold = function(game) return tostring(game.gold) end,
    lives = function(game) return tostring(game.lives) end,
    wave = function(game) return "Wave " .. game.wave .. " / " .. game.waves end,
}

function Label:start(dt)
    self.format = FORMATS[getProps(self.entity).show]
end

function Label:update(dt)
    getText(self.entity).value = self.format(State.game)
end

return Label
