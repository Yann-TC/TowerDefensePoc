-- The message of the game, centered on top of the map and fading out. Its
-- first child is the dark strip behind it: a Rectangle, sized to the width
-- of the text.
local State = require("state")
local Util = require("util")

local Banner = {}

local PADDING = 40 -- Pixels of strip around the text

function Banner:start(dt)
    self.back = getChildren(self.entity)[1]
end

function Banner:update(dt)
    local game = State.game
    local text = getText(self.entity)
    text.value = game.message
    Util.centerText(self.entity, Util.MAP_WIDTH / 2)
    local alpha = Util.clamp(game.messageTime * 2, 0, 1)
    text.color.a = math.floor(255 * alpha)

    -- The strip is a child: its position is relative to the text.
    local width = Util.textWidth(game.message, text.size) + PADDING
    local back = getRectangle(self.back)
    back.size.x = width
    getTransform(self.back).position.x = Util.MAP_WIDTH / 2 - width / 2 - getTransform(self.entity).position.x
    Util.setColor(back.fill, 0, 0, 0, 140 * alpha)
end

return Banner
