local State = {
    game = nil,
    level = nil,
    session = { scene = "", name = "", won = false, wave = 0, waves = 0 },
    enemies = {},
    enemyOf = {},
    towerOf = {},
    shotOf = {},
    sounds = {},
    booms = 0,
    pointer = { x = 0, y = 0 },
    pointed = {},
}

function State.isPointed(entity)
    for _, other in ipairs(State.pointed) do
        if other == entity then
            return true
        end
    end
    return false
end

function State.newGame(gold, lives)
    return {
        gold = gold,
        lives = lives,
        wave = 0,
        waves = 0,
        countdown = 0,
        speed = 1,
        paused = false,
        playing = false,
        building = nil,
        selected = nil,
        request = "",
        argument = "",
        message = "",
        messageTime = 0,
    }
end

State.game = State.newGame(0, 0)

function State.reset()
    State.enemies = {}
    State.enemyOf = {}
    State.towerOf = {}
    State.shotOf = {}
    State.sounds = {}
    State.booms = 0
end

function State.message(text, seconds)
    State.game.message = text
    State.game.messageTime = seconds or 2
end

function State.playSound(name)
    local sound = State.sounds[name]
    if sound and hasAudioSource(sound) then
        getAudioSource(sound).playing = true
    end
end

return State
