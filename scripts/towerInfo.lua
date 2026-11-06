-- The text of the panel about the selected tower: its name, level and
-- stats, or how to select one.
local State = require("state")
local TowerKinds = require("towerKinds")

local TowerInfo = {}

local BUILDING_HELP = "Click on the grass\nto build the tower.\nHold Shift to build\nseveral. Right click\nor Esc to cancel."
local IDLE_HELP = "Pick a tower above\n(keys 1 to 4, Q / E), then\nclick on the grass.\nClick a tower to\nupgrade or sell it."

local function describe(tower)
    local data = TowerKinds[tower.kind]
    local stats = data.levels[tower.level]
    local targets = (data.air and data.ground) and "air + ground"
        or (data.air and "air only" or "ground only")
    return table.concat({
        data.name .. "   level " .. tower.level .. "/" .. #data.levels,
        "Damage  " .. stats.damage .. ((stats.splash or 0) > 0 and "  (area)" or ""),
        "Range   " .. stats.range,
        "Rate    " .. stats.rate .. " / s",
        "Hits    " .. targets,
    }, "\n")
end

function TowerInfo:update(dt)
    local game = State.game
    local text = getText(self.entity)
    if game.selected then
        text.value = describe(game.selected)
    elseif game.building then
        text.value = BUILDING_HELP
    else
        text.value = IDLE_HELP
    end
end

return TowerInfo
