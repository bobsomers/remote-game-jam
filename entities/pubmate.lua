local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local PubMate = Class(function(self, collider)
    self.collider = collider

    self.SIZE = Vector(32, 64)

    self.shape = self.collider:addRectangle(0, 0, self.SIZE.x, self.SIZE.y)
    self.shape.kind = "pubmate"
    self.collider:addToGroup("pubmate", self.shape)

    self.MOVE_SPEED = (Constants.PLAYER_SPEED / 4)
    self.JUMP_VELOCITY = (-Constants.PLAYER_JUMP / 4)

    self:reset()
end)

function PubMate:reset()
    self.velocity = Vector(0, 0)
    self.DRUNK_DRAIN_RATE = math.random(Constants.PUBMATE_DRUNK_DRAIN_RATE_MIN,
        Constants.PUBMATE_DRUNK_DRAIN_RATE_MAX)
    self.PUNCH_DAMAGE = math.random(Constants.PUBMATE_PUNCH_DAMAGE_MIN,
        Constants.PUBMATE_PUNCH_DAMAGE_MAX)
    self.health = 100
    self.drunk = 100
    self.alive = true
    self.collider:setSolid(self.shape)
    self.punchCooldown = 0
end

function PubMate:kill()
    self.alive = false
    self.collider:setGhost(self.shape)
end

function PubMate:jump()
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

function PubMate:collideWorld(tileShape, mtv)
    -- Apply minimum translation vector to resolve the collision.
    self.shape:move(mtv.x, mtv.y)    

    -- If we corrected the player in the Y direction, their Y velocity is 0.
    if mtv.y ~= 0 then
        self.velocity.y = 0
    end
end

function PubMate:attackBro(bro, mtv)
    -- Damage the bro.
    if self.punchCooldown < 0 then
        bro.health = bro.health - self.PUNCH_DAMAGE
        self.punchCooldown = Constants.PUBMATE_PUNCH_COOLDOWN
        print("PUBMATE PUNCH")
    end

    -- Resolve the collision by moving them double the MTV away from each other.
    self.shape:move(10 * mtv.x, 10 * mtv.y)
    bro.shape:move(-10 * mtv.x, -10 * mtv.y)
end

function PubMate:update(dt)
    if not self.alive then return end
    if self.health <= 0 then
        self:kill()
        return
    end

    -- Reduce their punch cooldown.
    self.punchCooldown = self.punchCooldown - dt

    -- Slowly drain the player's drunkeness over time.
    self.drunk = self.drunk - (self.DRUNK_DRAIN_RATE * dt)
    if self.drunk < 0 then
        self.drunk = 0
        -- TODO: pubmate dies!
    end

    -- Always be moving right
    self.velocity.x = self.MOVE_SPEED

    -- Compute player's position based on velocity and gravity.
    local posX, posY = self.shape:center()
    posX = posX + (self.velocity.x * dt) -- No acceleration in X direction.
    posY = posY + (self.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

    -- Update the player's velocity due to gravity.
    self.velocity.y = self.velocity.y + (Constants.GRAVITY * dt)

    self.shape:moveTo(posX, posY)
end

function PubMate:draw()
    if not self.alive then return end

    local posX, posY = self.shape:center()
    local position = Vector(posX, posY)

    love.graphics.setColor(0, 255, 0, 255)
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

return PubMate
