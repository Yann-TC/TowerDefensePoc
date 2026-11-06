-- The metrics, shown or hidden with Tab. They all come from the Stats
-- resource of the engine (getStats): the ones the Scheduler
-- measures every frame (FPS, frame and update times, entities alive, the
-- last frame times), and the ones the game puts in its values (enemies,
-- towers, refused spawns: see State.METRICS). Its Props:
--   shown  whether it is shown when the level starts
-- Children: the dark Rectangle behind the text, then the graph: an entity
-- whose children are Lines, the first one marking 60 FPS, the others the
-- last frame times (oldest on the left).
--
-- The times are real ones (the Scheduler's clock), whatever the speed of the
-- game. The engine caps dt at 0.1 s, so below 10 FPS the game slows down.
local Util = require("util")

local Stats = {}

local GRAPH_HEIGHT = 56   -- Pixels of the graph
local GRAPH_MAX_MS = 50   -- Frame time at the top of the graph
local GRAPH_STEP = 2      -- Pixels between two frames
local SMOOTH_MS, SLOW_MS = 1000 / 60, 1000 / 30

local function heightOf(ms)
    return GRAPH_HEIGHT - Util.clamp(ms / GRAPH_MAX_MS, 0, 1) * GRAPH_HEIGHT
end

-- Green at 60 FPS, yellow down to 30, red below.
local function paint(color, ms)
    if ms <= SMOOTH_MS + 1 then
        Util.setColor(color, 90, 220, 90, 255)
    elseif ms <= SLOW_MS + 1 then
        Util.setColor(color, 240, 200, 60, 255)
    else
        Util.setColor(color, 240, 80, 70, 255)
    end
end

function Stats:start(dt)
    self.shown = getProps(self.entity).shown == true
    local graph = getChildren(self.entity)[2]
    local lines = getChildren(graph)
    local target = getLine(lines[1])
    target.from.y, target.to.y = heightOf(SMOOTH_MS), heightOf(SMOOTH_MS)
    self.bars = { table.unpack(lines, 2) }
end

function Stats:update(dt)
    if input.getButtonDown("Stats") then
        self.shown = not self.shown
    end
    Util.setShown(self.entity, self.shown)
    if self.shown then
        local stats = getStats()
        getText(self.entity).value = self:describe(stats)
        self:drawGraph(stats:history())
    end
end

function Stats:describe(stats)
    return string.format(
        "FPS %d   frame %.1f ms   update %.1f ms\n"
        .. "Entities %d   enemies %d (peak %d)\n"
        .. "Towers %d   spawns refused %d",
        math.floor(stats.fps + 0.5), stats.frameMs, stats.updateMs,
        stats.entities, stats:value("game.enemies"), stats:value("game.enemiesPeak"),
        stats:value("game.towers"), stats:value("game.spawnsRefused"))
end

-- One Line per pair of frames: from the time of a frame to the next one.
function Stats:drawGraph(history)
    local first = #history - #self.bars - 1
    for i, bar in ipairs(self.bars) do
        local before, after = history[first + i], history[first + i + 1]
        local line = getLine(bar)
        line.from.x, line.from.y = (i - 1) * GRAPH_STEP, heightOf(before)
        line.to.x, line.to.y = i * GRAPH_STEP, heightOf(after)
        paint(line.color, after)
    end
end

return Stats
