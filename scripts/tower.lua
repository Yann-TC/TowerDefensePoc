-- A tower, created by Units.spawnTower: turns its turret to the enemy in range
-- that is the closest to the end of the path, and fires at it. Its stats are
-- the levels of its kind in towerKinds.lua.
--
-- Children, in this order: the turret (a Sprite with an
-- AnimationStateMachine), the range and the level pips (Circles), and the
-- sound of its shots (AudioSource). Their positions are relative to the top
-- left corner of the base (the origin of the tower is its center, at
-- (32, 32)). Its BoxCollider lets the pointer select it.
--
-- The machine of the turret picks its sprite from two params set here:
-- "level" (the gun and cannon change at level 3, the rocket at level 2) and
-- "loaded" (the rocket and missile look empty while reloading).
local State = require("state")
local TowerKinds = require("towerKinds")
local Units = require("units")
local Util = require("util")
local Fx = require("fx")

local Tower = {}

local SCAN_DELAY = 0.15 -- Seconds between two searches for a better target
local AIM_TOLERANCE = 15 -- Degrees off the target it can still fire at
local RELOAD_SHOWN = 0.35 -- Part of the reload during which it looks empty

function Tower:start(dt)
    self.entry = State.towerOf[self.entity.index]
    self.data = TowerKinds[self.entry.kind]
    self.cooldown = 0
    self.level = 0
    self.angle = -90
    self.scan = 0
    self.pips = {}
    for _, child in ipairs(getChildren(self.entity)) do
        if hasAudioSource(child) then
            self.sound = child
        elseif not self.turret then
            self.turret = child
        elseif not self.range then
            self.range = child
        else
            table.insert(self.pips, child)
        end
    end
end

function Tower:update(dt)
    if self.entry.level ~= self.level then
        self:setLevel(self.entry.level)
    end
    if self.entry.placed then
        self:aim(dt)
    end
    self:showTurret()
    self:showRange()
    self:showPips()
end

function Tower:stats()
    return self.data.levels[self.entry.level]
end

function Tower:canHit(enemy)
    if enemy.flying then
        return self.data.air
    end
    return self.data.ground
end

-- The range circle is centered on the tower: its origin is its center.
function Tower:setLevel(level)
    self.level = level
    animation.setFloat(self.turret, "level", level)
    local range = self:stats().range
    getCircle(self.range).radius = range
    local origin = getTransform(self.range).origin
    origin.x, origin.y = range, range
end

---------------------------------------------------------------- firing

function Tower:aim(dt)
    self.cooldown = math.max(0, self.cooldown - dt)
    local stats = self:stats()
    local x, y = Util.position(self.entity)
    local target = self:updateTarget(dt, x, y, stats.range)
    if not target then
        return
    end
    local wanted = Util.angleTo(x, y, target.x, target.y)
    self.angle = Util.turnToward(self.angle, wanted, self.data.turn * dt)
    if self.cooldown <= 0 and math.abs(Util.angleDelta(self.angle, wanted)) < AIM_TOLERANCE then
        self:fire(target, stats)
    end
end

-- Keeps its target while it is alive and in range, and looks for a better
-- one a few times per second only: the enemies are many, the towers too.
function Tower:updateTarget(dt, x, y, range)
    local target = self.target
    local valid = target and not target.dead and target.health > 0
        and Util.distance(x, y, target.x, target.y) <= range
    self.scan = self.scan - dt
    if not valid or self.scan <= 0 then
        self.scan = SCAN_DELAY
        self.target = self:findTarget(x, y, range)
    end
    return self.target
end

-- The enemy in range that is the closest to the end of the path.
function Tower:findTarget(x, y, range)
    local best = nil
    local rangeSquared = range * range
    for enemy in pairs(State.enemies) do
        if enemy.health > 0 and (not best or enemy.progress > best.progress) and self:canHit(enemy) then
            local dx, dy = enemy.x - x, enemy.y - y
            if dx * dx + dy * dy <= rangeSquared then
                best = enemy
            end
        end
    end
    return best
end

-- The shot leaves the end of the barrel; projectile.lua reads what it must
-- do in State.shotOf.
function Tower:fire(target, stats)
    self.cooldown = 1 / stats.rate
    local x, y = Util.position(self.entity)
    local rad = math.rad(self.angle)
    local mx = x + math.cos(rad) * self.data.muzzle
    local my = y + math.sin(rad) * self.data.muzzle
    local shot = Fx.trySpawn(self.data.projectile, mx, my)
    if not shot then
        return
    end
    State.shotOf[shot.index] = {
        target = target, damage = stats.damage, splash = stats.splash or 0,
        air = self.data.air, ground = self.data.ground, x = target.x, y = target.y,
    }
    Util.setRotation(shot, self.angle + 90)
    if self.data.flash then
        local flash = Fx.trySpawn("world/prefabs/fx/flash.json", mx, my)
        if flash then
            Util.setRotation(flash, self.angle + 90)
        end
    end
    getAudioSource(self.sound).playing = true
end

---------------------------------------------------------------- look
-- Each part is only changed when it must; the children follow the tower by
-- themselves, and the pips are placed under it by the prefab.

-- Turned to its angle; its sprite is left to its AnimationStateMachine.
function Tower:showTurret()
    if self.angle ~= self.shownAngle then
        self.shownAngle = self.angle
        Util.setRotation(self.turret, self.angle + 90)
    end
    local loaded = self.cooldown <= RELOAD_SHOWN / self:stats().rate
    if loaded ~= self.shownLoaded then
        self.shownLoaded = loaded
        animation.setBool(self.turret, "loaded", loaded)
    end
end

-- The range shows while placing the tower or when it is selected.
function Tower:showRange()
    local shown = not self.entry.placed or State.game.selected == self.entry
    if shown ~= self.shownRange then
        self.shownRange = shown
        local circle = getCircle(self.range)
        Util.setColor(circle.fill, 255, 255, 255, shown and 35 or 0)
        Util.setColor(circle.outline, 255, 255, 255, shown and 150 or 0)
    end
end

-- One lit pip per level, once placed.
function Tower:showPips()
    local pips = self.entry.placed and self.level or 0
    if pips ~= self.shownPips then
        self.shownPips = pips
        for i, pip in ipairs(self.pips) do
            Util.setColor(getCircle(pip).fill, 255, 210, 60, i <= pips and 255 or 0)
        end
    end
end

function Tower:onDestroy(dt)
    if self.entry then
        Units.forgetTower(self.entry)
    end
end

return Tower
