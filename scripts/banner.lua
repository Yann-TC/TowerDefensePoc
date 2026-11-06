-- Child: the dark strip behind the text (a Rectangle).
local State = require("state")
local Util = require("util")

local Banner = {}

local STRIP_PADDING = 40

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

    local width = Util.textWidth(game.message, text.size) + STRIP_PADDING
    local back = getRectangle(self.back)
    back.size.x = width
    getTransform(self.back).position.x = Util.MAP_WIDTH / 2 - width / 2 - getTransform(self.entity).position.x
    Util.setColor(back.fill, 0, 0, 0, 140 * alpha)
end

return Banner
