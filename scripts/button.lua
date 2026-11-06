-- A button: a Rectangle with an outline, its position being its top left
-- corner. Lit when the mouse is over it, pressed with a click or with its
-- key; the pointer hovers it through their BoxColliders (see pointer.lua).
-- Its Props:
--   action    scene, retry, menu (done here), or build, upgrade, sell, wave,
--             speed, pause (asked to the level through State.game.request)
--   argument  scene to load, or kind of tower to build
--   key       virtual button of the InputManager that presses it (optional)
-- Its BoxCollider is sized here like its Rectangle. Its first Text child is
-- its label, the second one (optional) is filled here: the cost of a tower,
-- the refund of a sale, the next wave countdown...
local State = require("state")
local TowerKinds = require("towerKinds")
local Util = require("util")

local Button = {}

-- The state of a selected tower's button: upgrade cost or sale refund.
local function towerState(tower, action)
    if not tower then
        return false, "", false
    end
    if action == "sell" then
        return true, "+" .. math.floor(tower.spent * TowerKinds.sellRatio), false
    end
    local nextLevel = TowerKinds[tower.kind].levels[tower.level + 1]
    if not nextLevel then
        return false, "MAX", false
    end
    return true, nextLevel.cost .. " g", false
end

-- For each action: whether it can be pressed, its detail text, whether it
-- is lit. The actions not listed are always enabled, never lit.
local STATES = {
    build = function(game, argument)
        return true, TowerKinds[argument].levels[1].cost .. " g", game.building == argument
    end,
    upgrade = function(game) return towerState(game.selected, "upgrade") end,
    sell = function(game) return towerState(game.selected, "sell") end,
    wave = function(game)
        local detail = game.countdown > 0 and string.format("in %ds", math.ceil(game.countdown)) or ""
        return game.wave < game.waves, detail, game.countdown > 0
    end,
    speed = function(game) return true, "x" .. game.speed, game.speed > 1 end,
    pause = function(game) return true, nil, game.paused end,
}

-- The actions done by the button itself; the others are asked to the level.
local PRESSES = {
    scene = function(argument) Util.changeScene(argument) end,
    retry = function() Util.changeScene(State.session.scene) end,
    menu = function() Util.changeScene("menu") end,
}

function Button:start(dt)
    self.props = getProps(self.entity)
    local box = getRectangle(self.entity)
    self.color = { box.fill.r, box.fill.g, box.fill.b, box.fill.a }
    local bounds = getBoxCollider(self.entity).bounds
    bounds.x, bounds.y = 0, 0
    bounds.width, bounds.height = box.size.x, box.size.y
    self.texts = {}
    for _, child in ipairs(getChildren(self.entity)) do
        if hasText(child) then
            table.insert(self.texts, child)
        end
    end
end

function Button:update(dt)
    local enabled, detail, active = self:state()
    if self.texts[2] and detail then
        getText(self.texts[2]).value = detail
    end
    local hovered = State.isPointed(self.entity)
    self:paint(enabled, hovered, active)
    local key = self.props.key and input.getButtonDown(self.props.key)
    if enabled and (key or (hovered and input.getButtonDown("Select"))) then
        self:press()
    end
end

function Button:state()
    local state = STATES[self.props.action]
    if not state then
        return true, nil, false
    end
    return state(State.game, self.props.argument)
end

function Button:paint(enabled, hovered, active)
    local r, g, b, a = table.unpack(self.color)
    local light = (active and 45) or ((hovered and enabled) and 30) or 0
    local box = getRectangle(self.entity)
    Util.setColor(box.fill, r + light, g + light, b + light, a)
    Util.setColor(box.outline, 255, 255, 255, (hovered and enabled) and 220 or 70)
    for _, text in ipairs(self.texts) do
        getText(text).color.a = enabled and 255 or 110
    end
end

function Button:press()
    State.playSound("click")
    local press = PRESSES[self.props.action]
    if press then
        press(self.props.argument)
    else
        State.game.request = self.props.action
        State.game.argument = self.props.argument or ""
    end
end

return Button
