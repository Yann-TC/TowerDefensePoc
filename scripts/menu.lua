-- After map.lua. Props: towers ({ kind, col, row, level }), enemies (prefabs
-- picked at random), interval (seconds between two enemies).
local State = require("state")
local Units = require("units")

local Menu = {}

function Menu:start(dt)
    self.props = getProps(self.entity)
    self.timer = 1
    State.game = State.newGame(0, 0)
    setTimeScale(1)
    Units.buildTowers(self.props.towers)
end

function Menu:update(dt)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.timer = self.props.interval
        local enemies = self.props.enemies
        Units.spawnEnemy(enemies[math.random(1, #enemies)])
    end
end

return Menu
