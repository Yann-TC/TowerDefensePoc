-- After game.lua. Props: waves ({ groups = { enemy, count, interval, delay,
-- health }, bonus }), difficulty (health multiplier, optional).
local State = require("state")
local Units = require("units")
local Util = require("util")
local Fx = require("fx")

local Waves = {}

local SECONDS_BETWEEN_WAVES = 15
local EARLY_BONUS_PER_SECOND = 2
local RESULT_DELAY = 3

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

function Waves:call(game)
    if game.wave >= #self.waves then
        return
    end
    if game.countdown > 1 then
        local bonus = math.floor(game.countdown) * EARLY_BONUS_PER_SECOND
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
    game.countdown = SECONDS_BETWEEN_WAVES
end

function Waves:startEnding(game, won)
    self.ending = RESULT_DELAY
    local session = State.session
    session.scene = getCurrentScene()
    session.name = State.level.name
    session.won = won
    session.wave = won and game.wave or math.max(0, game.wave - 1)
    session.waves = #self.waves
    State.message(won and "VICTORY!" or "DEFEAT", RESULT_DELAY)
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
