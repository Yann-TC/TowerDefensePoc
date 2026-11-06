-- The state shared by the scripts, with require("state"): the module is
-- loaded once, so every script reads and changes the same table, and it
-- keeps its values from one scene to the next.
local State = {
    -- The level being played: see newGame
    game = nil,
    -- The map: grid, path, towers built on each cell (see map.lua)
    level = nil,
    -- How the last level ended, for the result screen
    session = { scene = "", name = "", won = false, wave = 0, waves = 0 },
    -- The living enemies, towers and shots, by their entry (see units.lua
    -- and Tower:fire), and the entry of each entity index
    enemies = {},
    enemyOf = {},
    towerOf = {},
    shotOf = {},
    -- The sounds of the scene by name (see map.lua and playSound)
    sounds = {},
    -- Explosions heard this frame (see Fx.explode)
    booms = 0,
    -- The pointer (see pointer.lua): where it is, and the entities its
    -- BoxCollider touches
    pointer = { x = 0, y = 0 },
    pointed = {},
}

-- Whether the pointer touches the BoxCollider of an entity.
function State.isPointed(entity)
    for _, other in ipairs(State.pointed) do
        if other == entity then
            return true
        end
    end
    return false
end

-- The metrics of the game, kept in the values of the engine's Stats
-- resource (shown by stats.lua next to the ones of the engine).
State.METRICS = { "game.enemies", "game.enemiesPeak", "game.towers", "game.spawnsRefused" }

function State.addMetric(name, delta)
    local stats = getStats()
    stats:setValue(name, stats:value(name) + delta)
end

function State.newGame(gold, lives)
    return {
        gold = gold,
        lives = lives,
        wave = 0,          -- Number of waves started
        waves = 0,         -- Number of waves of the level
        countdown = 0,     -- Seconds before the next wave, 0 if none
        speed = 1,
        paused = false,
        playing = false,   -- False in the menus: the enemies cost no lives
        building = nil,    -- Kind of the tower being placed
        selected = nil,    -- Entry of the selected tower
        request = "",      -- Action asked by a button (see button.lua)
        argument = "",
        message = "",      -- Text of the banner
        messageTime = 0,
    }
end

State.game = State.newGame(0, 0)

-- Forgets every entity of the previous scene.
function State.reset()
    State.enemies = {}
    State.enemyOf = {}
    State.towerOf = {}
    State.shotOf = {}
    State.sounds = {}
    State.booms = 0
    for _, name in ipairs(State.METRICS) do
        getStats():setValue(name, 0)
    end
end

-- Shows a message in the banner on top of the map.
function State.message(text, seconds)
    State.game.message = text
    State.game.messageTime = seconds or 2
end

-- Plays a sound of the scene.
function State.playSound(name)
    local sound = State.sounds[name]
    if sound and hasAudioSource(sound) then
        getAudioSource(sound).playing = true
    end
end

return State
