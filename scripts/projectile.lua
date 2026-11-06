-- Props: speed, homing, explosion (scale, optional), trail (seconds between
-- two puffs, optional).
local State = require("state")
local Util = require("util")
local Fx = require("fx")

local Projectile = {}

local IMPACT_MARGIN = 4

function Projectile:start(dt)
    self.props = getProps(self.entity)
    self.shot = State.shotOf[self.entity.index]
    State.shotOf[self.entity.index] = nil
    self.trail = 0
end

function Projectile:update(dt)
    local shot = self.shot
    if self.props.homing and not shot.target.dead then
        shot.x, shot.y = shot.target.x, shot.target.y
    end
    local speed = self.props.speed
    local x, y = Util.position(self.entity)
    if Util.distance(x, y, shot.x, shot.y) <= speed * dt + IMPACT_MARGIN then
        self:hit()
        return
    end
    local angle = Util.angleTo(x, y, shot.x, shot.y)
    local velocity = getVelocity(self.entity).value
    velocity.x = math.cos(math.rad(angle)) * speed
    velocity.y = math.sin(math.rad(angle)) * speed
    Util.setRotation(self.entity, angle + 90)
    self:smoke(dt, x, y)
end

function Projectile:smoke(dt, x, y)
    if not self.props.trail then
        return
    end
    self.trail = self.trail - dt
    if self.trail <= 0 then
        self.trail = self.props.trail
        Fx.trySpawn("world/prefabs/fx/smoke.json", x, y)
    end
end

function Projectile:canHit(enemy)
    if enemy.flying then
        return self.shot.air
    end
    return self.shot.ground
end

function Projectile:hit()
    local shot = self.shot
    if shot.splash > 0 then
        for enemy in pairs(State.enemies) do
            if self:canHit(enemy) and Util.distance(shot.x, shot.y, enemy.x, enemy.y) <= shot.splash then
                enemy.health = enemy.health - shot.damage
            end
        end
    elseif not shot.target.dead then
        shot.target.health = shot.target.health - shot.damage
    end
    self:impact()
    destroy(self.entity)
end

function Projectile:impact()
    local shot = self.shot
    if self.props.explosion then
        Fx.explode(shot.x, shot.y, self.props.explosion)
        return
    end
    local spark = Fx.trySpawn("world/prefabs/fx/spark.json", shot.x, shot.y)
    if spark then
        Util.setRotation(spark, math.random(0, 89))
    end
end

return Projectile
