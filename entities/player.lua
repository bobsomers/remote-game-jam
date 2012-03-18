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

    self.facing = "left"
    
    self:reset()
end)

function Player:reset()
    self.velocity = Vector(0, 0)
    self.health = 100
    self.drunk = 100
    self.jumping = false
end

function Player:jump()
    if self.velocity.y > 0 then
        return
    end
    
    if self.velocity.y < 0 then     
        return
    end
    
    print("Jumping!")
    self.jumping = true
    
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
        self.jumping = false
        print("Not jumping!")
    end
end

function Player:update(dt)
    -- Slowly drain the player's drunkeness over time.
    self.drunk = self.drunk - (Constants.PLAYER_DRUNK_DRAIN_RATE * dt)
    if self.drunk < 0 then
        self.drunk = 0
        -- TODO: you lose!
    end

    -- Check for keyboard input.
    self.velocity.x = 0
    if love.keyboard.isDown("a") then
        self.velocity.x = -self.MOVE_SPEED
        self.facing = "left"
    end
    if love.keyboard.isDown("d") then
        self.velocity.x = self.MOVE_SPEED
        self.facing = "right"
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
    local posX, posY = self.shape:center()
    local position = Vector(posX, posY)

    love.graphics.setColor(255, 0, 0, 255)
    self.shape:draw("fill") -- for debugging

    -- Draw their sobriety meter.
    love.graphics.setColor(255, 200, 0, 255)
    love.graphics.rectangle("fill",
        position.x - (self.SIZE.x / 2), position.y - (self.SIZE.y / 2) - 6,
        self.drunk / 100 * self.SIZE.x, 4
    )

    -- Draw their health meter.
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.rectangle("fill",
        position.x - (self.SIZE.x / 2), position.y - (self.SIZE.y / 2) - 12,
        self.health / 100 * self.SIZE.x, 4
    )

    love.graphics.setColor(255, 255, 255, 255)
end

return Player
