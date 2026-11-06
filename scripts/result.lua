-- The texts of the result screen, from State.session. Its children are the
-- title then the details.
local State = require("state")
local Util = require("util")

local Result = {}

local SCREEN_MIDDLE = 640

function Result:start(dt)
    local session = State.session
    local children = getChildren(self.entity)
    local title = getText(children[1])
    if session.won then
        title.value = "VICTORY!"
        Util.setColor(title.color, 255, 215, 64, 255)
    else
        title.value = "DEFEAT"
        Util.setColor(title.color, 255, 90, 80, 255)
    end
    getText(children[2]).value = session.name .. "  -  waves survived: "
        .. session.wave .. " / " .. session.waves
    Util.centerText(children[1], SCREEN_MIDDLE)
    Util.centerText(children[2], SCREEN_MIDDLE)
end

return Result
