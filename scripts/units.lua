-- The grid of the level, and the enemies and towers on it: their entries in
-- the State, created and removed here. An entry is the Lua side of a unit,
-- read by the other scripts (a tower reads the enemies, a shot its target).
local State = require("state")
local TowerKinds = require("towerKinds")
local Util = require("util")
local Fx = require("fx")

local Units = {}

---------------------------------------------------------------- grid

function Units.tileAt(col, row)
    local level = State.level
    if col < 0 or row < 0 or col >= level.cols or row >= level.rows then
        return " "
    end
    return level.grid[row + 1]:sub(col + 1, col + 1)
end

function Units.isPath(tile)
    return tile == "#" or tile == "S" or tile == "E"
end

function Units.cellAt(x, y)
    local size = State.level.size
    return math.floor(x / size), math.floor(y / size)
end

function Units.cellCenter(col, row)
    local size = State.level.size
    return col * size + size / 2, row * size + size / 2
end

-- The tower built on a cell, if any.
function Units.occupant(col, row)
    return State.level.towers[col .. "," .. row]
end

-- Grass ('.') with no tower on it.
function Units.canBuild(col, row)
    return Units.tileAt(col, row) == "." and Units.occupant(col, row) == nil
end

---------------------------------------------------------------- enemies

-- Creates an enemy at the start of the path. Its stats come from its Props,
-- its health is multiplied by healthScale. Returns nil if the World is full.
function Units.spawnEnemy(prefab, healthScale)
    local start = State.level.path[1]
    local entity = Fx.trySpawn(prefab, start.x, start.y)
    if not entity then
        return nil
    end
    local props = getProps(entity)
    local health = props.health * (healthScale or 1)
    local entry = {
        entity = entity, health = health, maxHealth = health,
        speed = props.speed, reward = props.reward, damage = props.damage,
        flying = props.flying == true, progress = 0,
        x = start.x, y = start.y, -- Kept up to date by enemy.lua
    }
    State.enemies[entry] = true
    State.enemyOf[entity.index] = entry
    State.addMetric("game.enemies", 1)
    local stats = getStats()
    stats:setValue("game.enemiesPeak", math.max(stats:value("game.enemiesPeak"), stats:value("game.enemies")))
    return entry
end

-- The enemy is out of the game (killed, leaked, or its entity destroyed by
-- a scene change): the scripts stop seeing it.
function Units.forgetEnemy(entry)
    entry.dead = true
    if State.enemies[entry] then
        State.enemies[entry] = nil
        State.addMetric("game.enemies", -1)
    end
    if State.enemyOf[entry.entity.index] == entry then
        State.enemyOf[entry.entity.index] = nil
    end
end

function Units.removeEnemy(entry)
    Units.forgetEnemy(entry)
    destroy(entry.entity)
end

---------------------------------------------------------------- towers

-- Creates a tower of a kind, not placed yet (it follows the mouse until it
-- is). Returns nil if the World is full.
function Units.spawnTower(kind, x, y)
    local entity = Fx.trySpawn(TowerKinds[kind].prefab, x, y)
    if not entity then
        return nil
    end
    local entry = { entity = entity, kind = kind, level = 1, spent = 0, placed = false }
    State.towerOf[entity.index] = entry
    State.addMetric("game.towers", 1)
    return entry
end

-- The tower is out of the game (sold, cancelled, or its entity destroyed by
-- a scene change).
function Units.forgetTower(entry)
    entry.dead = true
    if entry.col and Units.occupant(entry.col, entry.row) == entry then
        State.level.towers[entry.col .. "," .. entry.row] = nil
    end
    if State.towerOf[entry.entity.index] == entry then
        State.towerOf[entry.entity.index] = nil
        State.addMetric("game.towers", -1)
    end
end

function Units.removeTower(entry)
    Units.forgetTower(entry)
    destroy(entry.entity)
end

-- Builds a tower on a cell.
function Units.placeTower(entry, col, row)
    entry.placed = true
    entry.col, entry.row = col, row
    State.level.towers[col .. "," .. row] = entry
    Util.moveTo(entry.entity, Units.cellCenter(col, row))
end

-- Builds the towers given by a scene: list of { kind, col, row, level }.
function Units.buildTowers(list)
    for _, tower in ipairs(list or {}) do
        local entry = Units.spawnTower(tower.kind, 0, 0)
        if not entry then
            return
        end
        entry.level = tower.level or 1
        for level = 1, entry.level do
            entry.spent = entry.spent + TowerKinds[tower.kind].levels[level].cost
        end
        Units.placeTower(entry, tower.col, tower.row)
    end
end

-- Color of the base and the turret (first child) of a tower.
function Units.tintTower(entry, r, g, b, a)
    Util.setColor(getSprite(entry.entity).color, r, g, b, a)
    Util.setColor(getSprite(getChildren(entry.entity)[1]).color, r, g, b, a)
end

return Units
