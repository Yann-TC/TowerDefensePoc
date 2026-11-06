-- A short-lived effect (explosion, flash, smoke, popup text, debris). Its
-- Props:
--   life  seconds before it is removed
--   grow  scale added per second
--   spin  degrees per second
--   fade  whether it fades out (true if not given)
-- A Velocity in the prefab moves it (MovementSystem, which also pulls it
-- down with a Gravity: the debris), an Animation plays its frames
-- (AnimationSystem): the script only does the rest.
local Util = require("util")

local Effect = {}

function Effect:start(dt)
    local props = hasProps(self.entity) and getProps(self.entity) or {}
    self.life = props.life or 0.5
    self.grow = props.grow or 0
    self.spin = props.spin or 0
    self.fade = props.fade ~= false
    self.time = 0
    self.scale = getTransform(self.entity).scale.x
    self.alpha = Util.mainColor(self.entity).a
end

function Effect:update(dt)
    self.time = self.time + dt
    local t = self.time / self.life
    if t >= 1 then
        destroy(self.entity)
        return
    end
    local transform = getTransform(self.entity)
    Util.setScale(self.entity, self.scale + self.grow * self.time)
    transform.rotationDegrees.z = transform.rotationDegrees.z + self.spin * dt
    if self.fade then
        Util.setAlpha(self.entity, self.alpha * (1 - t * t))
    end
end

return Effect
