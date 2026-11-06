-- The waves of the level (on the "Level" entity, after game.lua), from the
-- "waves" of its Props:
--   { "groups": [ { "enemy": prefab, "count", "interval", "delay", "health" } ],
--     "bonus": gold given when the wave is cleared }
-- "delay" waits before the first enemy of the group, "health" multiplies
-- the health of its enemies (both optional). The "difficulty" of the level
-- multiplies the health of every enemy (optional).
--
-- The first wave starts when the player asks for it (SPACE or the button),
-- the next ones after a countdown, or sooner for a bonus. The level is won
-- when the last wave is cleared, lost when there are no lives left.
local State = require("state")
local Units = require("units")
local Util = require("util")
local Fx = require("fx")

local Waves = {}

local PAUSE = 15        -- Seconds between two waves
local EARLY_BONUS = 2   -- Gold per second left when a wave is called early
local END_DELAY = 3     -- Seconds before the result screen

function Waves:start(dt)
    self.waves = State.level.waves
    self.difficulty = getProps(self.entity).difficulty or 1
    self.spawners = {}
    State.game.waves = #self.waves
    State.message("Build towers, then press SPACE to start", 5)
end

function Waves:update(dt)
    local game = State.game
    if self.ending then
        self:finish(dt)
        return
    end
    if game.request == "wave" then
        game.request = ""
        self:call(game)
    end
    if game.countdown > 0 then
        game.countdown = game.countdown - dt
        if game.countdown <= 0 then
            self:call(game)
        end
    end
    self:runSpawners(dt)
    self:checkEnd(game)
end

-- Starts the next wave; called early, it gives a bonus.
function Waves:call(game)
    if game.wave >= #self.waves then
        return
    end
    if game.countdown > 1 then
        local bonus = math.floor(game.countdown) * EARLY_BONUS
        game.gold = game.gold + bonus
        Fx.popup("+" .. bonus .. " early bonus", Util.MAP_WIDTH / 2 - 80, 80)
    end
    game.countdown = 0
    game.wave = game.wave + 1
    for _, group in ipairs(self.waves[game.wave].groups) do
        table.insert(self.spawners, { group = group, left = group.count, timer = group.delay or 0 })
    end
    State.message("Wave " .. game.wave .. " / " .. #self.waves, 2.5)
    State.playSound("wave")
end

function Waves:runSpawners(dt)
    for i = #self.spawners, 1, -1 do
        local spawner = self.spawners[i]
        spawner.timer = spawner.timer - dt
        while spawner.left > 0 and spawner.timer <= 0 do
            Units.spawnEnemy(spawner.group.enemy, (spawner.group.health or 1) * self.difficulty)
            spawner.left = spawner.left - 1
            spawner.timer = spawner.timer + spawner.group.interval
        end
        if spawner.left == 0 then
            table.remove(self.spawners, i)
        end
    end
end

function Waves:checkEnd(game)
    if game.lives <= 0 then
        self:startEnding(game, false)
        return
    end
    local cleared = game.wave > 0 and game.countdown <= 0
        and #self.spawners == 0 and next(State.enemies) == nil
    if not cleared then
        return
    end
    local bonus = self.waves[game.wave].bonus or 0
    game.gold = game.gold + bonus
    if game.wave >= #self.waves then
        self:startEnding(game, true)
        return
    end
    State.message("Wave cleared!  +" .. bonus .. " gold", 2.5)
    game.countdown = PAUSE
end

-- Keeps the result for the result screen, which shows it after a while.
function Waves:startEnding(game, won)
    self.ending = END_DELAY
    local session = State.session
    session.scene = getCurrentScene()
    session.name = State.level.name
    session.won = won
    session.wave = won and game.wave or math.max(0, game.wave - 1)
    session.waves = #self.waves
    State.message(won and "VICTORY!" or "DEFEAT", END_DELAY)
    State.playSound(won and "victory" or "defeat")
end

function Waves:finish(dt)
    self.ending = self.ending - dt
    if self.ending <= 0 then
        self.ending = math.huge
        Util.changeScene("gameover")
    end
end

return Waves
