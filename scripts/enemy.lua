-- An enemy, created by Units.spawnEnemy: walks along the path (or flies
-- straight over it), shows its health when hurt, gives its reward when killed
-- and costs lives when it reaches the end. Its stats are in its Props
-- (health, speed, reward, damage, flying), copied to its entry in
-- State.enemies.
--
-- It moves through the Velocity of the entity, applied by the MovementSystem:
-- the script only changes it at each corner, and the children follow. The
-- entity itself never turns, so its health bar stays flat: its first child
-- is its body, its last one its health bar (a Rectangle), the ones in
-- between (turret of a tank, shadow of a plane) turn with the body.
local State = require("state")
local Units = require("units")
local Util = require("util")
local Fx = require("fx")

local Enemy = {}

local TURN_SPEED = 400 -- Degrees per second
local FLASH = 0.08     -- Seconds of red when hit
local BIG_HEALTH = 200 -- From this health, the explosion is a big one

function Enemy:start(dt)
    self.entry = State.enemyOf[self.entity.index]
    self.route = self:buildRoute()
    self.total = self:routeLength()
    self.travelled = 0
    self.leg = 1
    self.flash = 0
    self.health = self.entry.health
    local children = getChildren(self.entity)
    self.body = children[1]
    self.bar = children[#children]
    self.parts = { table.unpack(children, 1, #children - 1) }
    self.barWidth = getRectangle(self.bar).size.x
    self:startLeg()
    self.angle = self.wanted
    self:face(self.angle)
end

function Enemy:update(dt)
    local entry = self.entry
    if entry.dead then
        return
    end
    if entry.health <= 0 then
        self:die()
        return
    end
    self:walk(dt)
    if not entry.dead then
        self:turn(dt)
        self:updateHealth(dt)
    end
end

---------------------------------------------------------------- route

-- The corners of the path, or only its two ends for a plane.
function Enemy:buildRoute()
    local path = State.level.path
    if self.entry.flying then
        return { path[1], path[#path] }
    end
    return path
end

function Enemy:routeLength()
    local length = 0
    for i = 1, #self.route - 1 do
        local a, b = self.route[i], self.route[i + 1]
        length = length + Util.distance(a.x, a.y, b.x, b.y)
    end
    return length
end

-- Heads to the next corner.
function Enemy:startLeg()
    local from, to = self.route[self.leg], self.route[self.leg + 1]
    self.target = to
    self.wanted = Util.angleTo(from.x, from.y, to.x, to.y)
    local rad = math.rad(self.wanted)
    local velocity = getVelocity(self.entity).value
    velocity.x = math.cos(rad) * self.entry.speed
    velocity.y = math.sin(rad) * self.entry.speed
end

-- Keeps its entry up to date (position, progress), and turns at the corners.
function Enemy:walk(dt)
    local entry = self.entry
    local x, y = Util.position(self.entity)
    entry.x, entry.y = x, y
    local step = entry.speed * dt
    self.travelled = self.travelled + step
    entry.progress = self.travelled / self.total
    if Util.distance(x, y, self.target.x, self.target.y) <= step then
        self:reachCorner()
    end
end

function Enemy:reachCorner()
    Util.moveTo(self.entity, self.target.x, self.target.y)
    self.leg = self.leg + 1
    if self.leg >= #self.route then
        self:leak()
    else
        self:startLeg()
    end
end

-- The body turns smoothly toward the way it goes.
function Enemy:turn(dt)
    if self.angle == self.wanted then
        return
    end
    self.angle = Util.turnToward(self.angle, self.wanted, TURN_SPEED * dt)
    if math.abs(Util.angleDelta(self.angle, self.wanted)) < 0.5 then
        self.angle = self.wanted
    end
    self:face(self.angle)
end

function Enemy:face(angle)
    for _, part in ipairs(self.parts) do
        Util.setRotation(part, angle)
    end
end

---------------------------------------------------------------- health

-- Flashes red and redraws the health bar, only when the health changed.
function Enemy:updateHealth(dt)
    local entry = self.entry
    if entry.health ~= self.health then
        self.health = entry.health
        self.flash = FLASH
        Util.setColor(getSprite(self.body).color, 255, 120, 120, 255)
        self:updateBar()
    elseif self.flash > 0 then
        self.flash = self.flash - dt
        if self.flash <= 0 then
            Util.setColor(getSprite(self.body).color, 255, 255, 255, 255)
        end
    end
end

-- Shorter and redder as the health goes down.
function Enemy:updateBar()
    local ratio = Util.clamp(self.entry.health / self.entry.maxHealth, 0, 1)
    local bar = getRectangle(self.bar)
    bar.size.x = self.barWidth * ratio
    Util.setColor(bar.fill, 255 * math.min(1, 2 - 2 * ratio), 220 * math.min(1, 2 * ratio), 60, 255)
end

-- Killed: the reward (in a level), an explosion.
function Enemy:die()
    local entry = self.entry
    local x, y = Util.position(self.entity)
    if State.game.playing then
        State.game.gold = State.game.gold + entry.reward
        Fx.popup("+" .. entry.reward, x - 10, y - 30)
    end
    local big = entry.maxHealth >= BIG_HEALTH
    Fx.explode(x, y, big and 1.6 or 0.8, big)
    Units.removeEnemy(entry)
end

-- Reached the end of the path: the player loses lives.
function Enemy:leak()
    local game = State.game
    if game.playing then
        local damage = self.entry.damage
        game.lives = math.max(0, game.lives - damage)
        State.message("-" .. damage .. (damage > 1 and " lives" or " life"), 1.5)
        State.playSound("leak")
    end
    Units.removeEnemy(self.entry)
end

function Enemy:onDestroy(dt)
    if self.entry then
        Units.forgetEnemy(self.entry)
    end
end

return Enemy
