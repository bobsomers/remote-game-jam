local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Player = Class(function(self, collider)
    self.SIZE = Vector(32, 64)
    self.shape = collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    collider:addToGroup("player", self.shape)
    self.velocity = Vector(0, 0)
end)

function Player:collideWorld(tileShape)
    print("Player resolver!")
end

function Player:update(dt)
    -- Update player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

    self.shape:moveTo(posX, posY)
end

function Player:draw()
    love.graphics.setColor(255, 0, 0, 255)
    self.shape:draw("fill") -- for debugging
    love.graphics.setColor(255, 255, 255, 255)
end

return Player
