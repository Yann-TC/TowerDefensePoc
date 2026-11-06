-- Props: x (center of the title).
local Util = require("util")

local Title = {}

function Title:start(dt)
    self.time = 0
    self.x = getProps(self.entity).x
end

function Title:update(dt)
    self.time = self.time + dt
    local scale = 1 + math.sin(self.time * 2.5) * 0.03
    Util.setScale(self.entity, scale)
    local text = getText(self.entity)
    getTransform(self.entity).position.x = self.x - Util.textWidth(text.value, text.size) * scale / 2
end

return Title
