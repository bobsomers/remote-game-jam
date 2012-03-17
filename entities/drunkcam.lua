local Class = require "hump.class"
local Vector = require "hump.vector"
local Camera = require "hump.camera"
local Constants = require "constants"

local DrunkCam = Class(function(self)
    self.SPRING_K = 0.9
    self.FRICTION = 0.77

    self.camera = Camera(Vector(0, 0), 1, 0)
    self.target = Vector(0, 0)
end)

function DrunkCam:reset()
    self.time = 0
    self.translateVelocity = Vector(0, 0)
end

function DrunkCam:teleport(position)
    self.target = position
    self.translateVelocity = Vector(0, 0)
end

function DrunkCam:focus(position)
    self.target = position
end

function DrunkCam:update(dt)
    self.time = self.time + dt

    local a = (self.target - self.camera.pos) * self.SPRING_K

    self.translateVelocity = (self.translateVelocity + a) * self.FRICTION
    self.camera.pos = self.camera.pos + self.translateVelocity * dt
end

function DrunkCam:draw()
    -- Nothing to do.
end

function DrunkCam:attach()
    self.camera:attach()
end

function DrunkCam:detach()
    self.camera:detach()
end

return DrunkCam
