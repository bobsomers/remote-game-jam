local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Player = Class(function(self, collider)
    self.SIZE = Vector(32, 64)

    self.shape = collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "player"
    collider:addToGroup("player", self.shape)

    self.MOVE_SPEED = Constants.PLAYER_SPEED
    self.JUMP_VELOCITY = -Constants.PLAYER_JUMP

    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
end

function Player:jump()
    --[[
    if self.velocity.y > 0 then
        -- Can't jump!
        return
    end
    --]]

    -- Apply some instantaneous velocity in the Y direction.
    local x, y = self.shape:center()
    self.shape:moveTo(x, y - 1)
    self.velocity.y = self.JUMP_VELOCITY
end

function Player:collideWorld(tileShape, mtv)
    -- Apply minimum translation vector to resolve the collision.
    self.shape:move(mtv.x, mtv.y)

    -- If we corrected the player in the Y direction, their Y velocity is 0.
    if mtv.y ~= 0 then
        self.velocity.y = 0
    end
end

function Player:update(dt)
    -- Check for keyboard input.
    self.velocity.x = 0
    if love.keyboard.isDown("a") then
        self.velocity.x = -self.MOVE_SPEED
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.MOVE_SPEED
    end

    -- Compute player's position based on velocity and gravity.
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
