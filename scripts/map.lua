-- The level of a scene, first script of its "Level" entity. Its Props:
--   name, tileSize, grid (rows of characters, see LEGEND), and for the
--   levels: gold, lives and waves (see waves.lua)
-- Builds the map (a ground tile per cell, the decorations, a border along
-- the path), finds the path from 'S' to 'E' through the '#', and keeps it all
-- in State.level. Its children with an AudioSource are the sounds of the
-- scene, named by the "sound" of their Props (see State.playSound).
local State = require("state")
local Units = require("units")
local Util = require("util")

local Map = {}

local TILES = "world/prefabs/tiles/"
local LEGEND = {
    ["."] = { "grass" },
    ["#"] = { "path" },
    ["S"] = { "path" },
    ["E"] = { "path" },
    ["T"] = { "grass", "tree" },
    ["t"] = { "grass", "bush" },
    ["p"] = { "grass", "plant" },
    ["B"] = { "grass", "bigTree" },
    ["r"] = { "grass", "rock" },
    ["R"] = { "grass", "bigRock" },
    ["o"] = { "grass", "pebble" },
    ["x"] = { "stone" },
}
local STEPS = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

function Map:start(dt)
    local props = getProps(self.entity)
    State.reset()
    State.level = {
        name = props.name, grid = props.grid,
        size = props.tileSize, cols = #props.grid[1], rows = #props.grid,
        waves = props.waves or {}, towers = {},
    }
    State.level.path = self:findPath()
    self:registerSounds()
    for row = 0, State.level.rows - 1 do
        for col = 0, State.level.cols - 1 do
            self:buildCell(col, row)
        end
    end
end

-- A new frame: the explosions can be heard again (see Fx.explode).
function Map:update(dt)
    State.booms = 0
end

function Map:registerSounds()
    for _, child in ipairs(getChildren(self.entity)) do
        if hasAudioSource(child) then
            State.sounds[getProps(child).sound] = child
        end
    end
end

function Map:find(wanted)
    for row = 0, State.level.rows - 1 do
        for col = 0, State.level.cols - 1 do
            if Units.tileAt(col, row) == wanted then
                return { col, row }
            end
        end
    end
    error("the grid has no '" .. wanted .. "'")
end

-- The path cell next to a cell, not seen yet.
local function nextCell(current, seen)
    for _, step in ipairs(STEPS) do
        local col, row = current[1] + step[1], current[2] + step[2]
        if Units.isPath(Units.tileAt(col, row)) and not seen[col .. "," .. row] then
            return { col, row }
        end
    end
    error("the path stops at column " .. current[1] .. ", row " .. current[2])
end

-- The cells from 'S' to 'E', each one next to the previous one.
function Map:walk()
    local cells = { self:find("S") }
    local seen = { [cells[1][1] .. "," .. cells[1][2]] = true }
    while Units.tileAt(cells[#cells][1], cells[#cells][2]) ~= "E" do
        local cell = nextCell(cells[#cells], seen)
        seen[cell[1] .. "," .. cell[2]] = true
        table.insert(cells, cell)
    end
    return cells
end

-- The corners of the path, from one tile before 'S' to one tile after 'E'
-- (outside the map when they are on its border).
function Map:findPath()
    local cells = self:walk()
    local points = {}
    for i, cell in ipairs(cells) do
        local before, after = cells[i - 1], cells[i + 1]
        if not before or not after or (before[1] ~= after[1] and before[2] ~= after[2]) then
            local x, y = Units.cellCenter(cell[1], cell[2])
            table.insert(points, { x = x, y = y })
        end
    end
    local function beyond(edge, inner)
        local x, y = Units.cellCenter(inner[1], inner[2])
        return { x = 2 * edge.x - x, y = 2 * edge.y - y }
    end
    table.insert(points, 1, beyond(points[1], cells[2]))
    table.insert(points, beyond(points[#points], cells[#cells - 1]))
    return points
end

function Map:buildCell(col, row)
    local tile = Units.tileAt(col, row)
    local x, y = Units.cellCenter(col, row)
    for index, name in ipairs(LEGEND[tile] or LEGEND["."]) do
        local entity = Util.spawnAt(TILES .. name .. ".json", x, y)
        if index > 1 then
            Util.setRotation(entity, math.random(0, 359))
        end
    end
    if Units.isPath(tile) then
        self:buildBorders(col, row, x, y)
    end
end

-- A dark line on each side of a path cell that touches the grass. None on
-- the border of the map: the path goes on there.
function Map:buildBorders(col, row, x, y)
    local half = State.level.size / 2
    local sides = {
        { 0, -1, "borderH", x - half, y - half },
        { 0, 1, "borderH", x - half, y + half - 4 },
        { -1, 0, "borderV", x - half, y - half },
        { 1, 0, "borderV", x + half - 4, y - half },
    }
    for _, side in ipairs(sides) do
        local neighbour = Units.tileAt(col + side[1], row + side[2])
        if neighbour ~= " " and not Units.isPath(neighbour) then
            Util.spawnAt(TILES .. side[3] .. ".json", side[4], side[5])
        end
    end
end

return Map
