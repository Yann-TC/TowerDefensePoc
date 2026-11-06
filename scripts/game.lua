-- The player in a level (on the "Level" entity, after map.lua): places the
-- towers (a ghost tower follows the pointer, snapped to the grid), selects
-- them, upgrades and sells them, pauses and speeds up the game. The buttons
-- of the HUD ask for actions through State.game.request; the "wave"
-- request is left to waves.lua.
--
-- Everything goes through the pointer (the mouse, see pointer.lua); a tower
-- is selected when the pointer touches its BoxCollider. Holding "Chain"
-- (Shift) keeps building the same tower after each one, releasing it stops;
-- "PreviousTower" / "NextTower" (Q / E) go through the towers to build.
--
-- Its child without an AudioSource is the frame drawn on the cell under the
-- pointer (a Rectangle with an outline).
-- The "towers" of its Props are built when the level starts (optional).
local State = require("state")
local TowerKinds = require("towerKinds")
local Units = require("units")
local Util = require("util")
local Fx = require("fx")

local Game = {}

-- What each request of a button does.
local REQUESTS = {
    build = function(self, kind) self:startBuilding(kind) end,
    upgrade = function(self) self:upgrade() end,
    sell = function(self) self:sell() end,
    speed = function() State.game.speed = 3 - State.game.speed end,
    pause = function() State.game.paused = not State.game.paused end,
}

function Game:start(dt)
    local props = getProps(self.entity)
    State.game = State.newGame(props.gold, props.lives)
    State.game.playing = true
    getClock().timeScale = 1
    Units.buildTowers(props.towers)
    for _, child in ipairs(getChildren(self.entity)) do
        if not hasAudioSource(child) then
            self.cursor = child
        end
    end
end

function Game:update(dt)
    local game = State.game
    game.messageTime = math.max(0, game.messageTime - dt)
    self:handleRequest(game)
    self:handleKeys(game)
    getClock().timeScale = game.paused and 0 or game.speed
    if game.paused then
        return
    end
    if self.ghost then
        self:moveGhost()
    elseif input.getButtonDown("Select") then
        self:clickMap()
    end
    self:updateCursor()
end

function Game:handleRequest(game)
    local action = REQUESTS[game.request]
    if action then
        game.request = ""
        action(self, game.argument)
    end
end

function Game:handleKeys(game)
    if input.getButtonDown("Pause") then
        self:escape(game)
    end
    if input.getButtonDown("Cancel") then
        self:cancel()
    end
    if input.getButtonUp("Chain") and self.chained then
        self:cancel()
    end
    if input.getButtonDown("PreviousTower") then
        self:cycleTower(-1)
    elseif input.getButtonDown("NextTower") then
        self:cycleTower(1)
    end
end

-- Escape cancels what is being done, or pauses.
function Game:escape(game)
    if self.ghost or game.selected then
        self:cancel()
    else
        game.paused = not game.paused
    end
end

function Game:cancel()
    if self.ghost then
        Units.removeTower(self.ghost)
        self.ghost = nil
        State.game.building = nil
    end
    self.chained = false
    State.game.selected = nil
end

-- The cell under the pointer, nil outside of the map.
function Game:pointerCell()
    local at = State.pointer
    if at.x < 0 or at.y < 0 or at.x >= Util.MAP_WIDTH then
        return nil
    end
    return Units.cellAt(at.x, at.y)
end

-- The placed tower whose BoxCollider the pointer touches, if any.
function Game:pointedTower()
    for _, other in ipairs(State.pointed) do
        local tower = State.towerOf[other.index]
        if tower and tower.entity == other and tower.placed then
            return tower
        end
    end
    return nil
end

function Game:refuse(text)
    State.message(text, 1.5)
    State.playSound("error")
end

-- The tower after (step 1) or before (step -1) the one being built.
function Game:cycleTower(step)
    local order = TowerKinds.order
    local index = 0
    for i, kind in ipairs(order) do
        if kind == State.game.building then
            index = i
        end
    end
    if index == 0 and step < 0 then
        index = 1
    end
    self:startBuilding(order[(index + step - 1) % #order + 1])
end

-- A second press on the same tower button stops building.
function Game:startBuilding(kind)
    local wasBuilding = State.game.building
    self:cancel()
    if wasBuilding == kind then
        return
    end
    if State.game.gold < TowerKinds[kind].levels[1].cost then
        self:refuse("Not enough gold")
        return
    end
    self.ghost = Units.spawnTower(kind, State.pointer.x, State.pointer.y)
    if not self.ghost then
        self:refuse("The world is full")
        return
    end
    State.game.building = kind
end

-- The ghost follows the pointer, green where it can be built, red elsewhere.
function Game:moveGhost()
    local col, row = self:pointerCell()
    local cost = TowerKinds[self.ghost.kind].levels[1].cost
    local valid = col and Units.canBuild(col, row) and State.game.gold >= cost
    if col then
        Util.moveTo(self.ghost.entity, Units.cellCenter(col, row))
    else
        Util.moveTo(self.ghost.entity, State.pointer.x, State.pointer.y)
    end
    if valid then
        Units.tintTower(self.ghost, 150, 255, 150, 210)
    else
        Units.tintTower(self.ghost, 255, 110, 110, 210)
    end
    if col and input.getButtonDown("Select") then
        if valid then
            self:build(col, row, cost)
        else
            self:refuse(State.game.gold < cost and "Not enough gold" or "You cannot build here")
        end
    end
end

-- Builds the ghost; with "Chain" held, a new ghost of the same kind follows.
function Game:build(col, row, cost)
    local tower = self.ghost
    self.ghost = nil
    State.game.gold = State.game.gold - cost
    State.game.building = nil
    tower.spent = cost
    Units.placeTower(tower, col, row)
    Units.tintTower(tower, 255, 255, 255, 255)
    State.playSound("build")
    Fx.trySpawn("world/prefabs/fx/dust.json", Units.cellCenter(col, row))
    if input.getButton("Chain") and State.game.gold >= cost then
        self:startBuilding(tower.kind)
        self.chained = true
    end
end

-- A click on a tower selects it, a click elsewhere on the map unselects.
function Game:clickMap()
    if not self:pointerCell() then
        return
    end
    State.game.selected = self:pointedTower()
    if State.game.selected then
        State.playSound("click")
    end
end

function Game:upgrade()
    local tower = State.game.selected
    if not tower then
        return
    end
    local nextLevel = TowerKinds[tower.kind].levels[tower.level + 1]
    if not nextLevel then
        self:refuse("Already at the maximum level")
    elseif State.game.gold < nextLevel.cost then
        self:refuse("Not enough gold")
    else
        State.game.gold = State.game.gold - nextLevel.cost
        tower.level = tower.level + 1
        tower.spent = tower.spent + nextLevel.cost
        State.playSound("upgrade")
        Fx.trySpawn("world/prefabs/fx/upgrade.json", Util.position(tower.entity))
    end
end

function Game:sell()
    local tower = State.game.selected
    if not tower then
        return
    end
    local refund = math.floor(tower.spent * TowerKinds.sellRatio)
    local x, y = Util.position(tower.entity)
    State.game.gold = State.game.gold + refund
    State.game.selected = nil
    Units.removeTower(tower)
    Fx.popup("+" .. refund, x - 14, y - 30)
    State.playSound("sell")
end

-- The frame on the cell under the pointer, while building or over a tower.
function Game:updateCursor()
    local col, row = self:pointerCell()
    if not col or not (self.ghost or self:pointedTower()) then
        Util.moveTo(self.cursor, -Util.HIDDEN, 0)
        return
    end
    local size = State.level.size
    Util.moveTo(self.cursor, col * size, row * size)
    local red = self.ghost and not Units.canBuild(col, row)
    local frame = getRectangle(self.cursor)
    local other = red and 80 or 255
    Util.setColor(frame.outline, 255, other, other, 220)
    Util.setColor(frame.fill, 255, other, other, 28)
end

return Game
