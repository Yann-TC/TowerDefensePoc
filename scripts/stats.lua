-- Props: shown (at the start of the scene). Child: the dark Rectangle behind the text.
local Util = require("util")

local Stats = {}

function Stats:start(dt)
    self.shown = getProps(self.entity).shown == true
end

function Stats:update(dt)
    if input.getButtonDown("Stats") then
        self.shown = not self.shown
    end
    Util.setShown(self.entity, self.shown)
    if self.shown then
        local stats = getStats()
        getText(self.entity).value = string.format(
            "FPS %d   frame %.1f ms   update %.1f ms\nEntities %d",
            math.floor(stats.fps + 0.5), stats.frameMs, stats.updateMs, stats.entities)
    end
end

return Stats
