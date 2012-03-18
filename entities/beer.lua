local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Beer = Class(function(self, player, collider)
    self.player = player
    self.collider = collider

    self.position = Vector(0, 0)
    self.direction = Vector(1, 0)

    self.particles = love.graphics.newParticleSystem(
        love.graphics.newImage("images/particle.png"), 250)
    self.particles:setEmissionRate(250)
    self.particles:setSize(1, 2, 1)
    self.particles:setSpeed(500, 700)
    self.particles:setColor(220, 105, 20, 255, 194, 30, 18, 0)
    self.particles:setLifetime(-1)
    self.particles:setParticleLife(0.4)
    self.particles:setSpread(math.pi / 10)
    self.particles:setTangentialAcceleration(1000)
    self.particles:setRadialAcceleration(-2000)

    self:reset()
end)

function Beer:reset()
    self.blobs = {}
    self.spraying = false
    self.cooldown = 0
end

function Beer:update(dt)
    self.cooldown = self.cooldown - dt

    if self.spraying then
        if self.cooldown < 0 then
            local position = Vector(self.player.shape:center()) +
                    (self.player.gunDirection *
                    (self.player.GUN_SIZE.x + Constants.BEER_BLOB_RADIUS))
            local shape = self.collider:addCircle(position.x, position.y,
                Constants.BEER_BLOB_RADIUS)

            shape.kind = "beer"
            shape.lifetime = Constants.BEER_BLOB_LIFETIME
            shape.velocity = self.player.gunDirection * Constants.BEER_BLOB_SPEED
            self.collider:addToGroup("beer", shape)
            table.insert(self.blobs, shape)

            local emitterAngle = math.atan2(self.player.gunDirection.y, self.player.gunDirection.x)
            self.particles:setPosition(position.x, position.y)
            self.particles:setDirection(emitterAngle)

            self.cooldown = Constants.BEER_COOLDOWN
        end
    end

    -- Update all blobs.
    for _, blob in ipairs(self.blobs) do
        blob.lifetime = blob.lifetime - dt
        
        local posX, posY = blob:center()
        posX = posX + (blob.velocity.x * dt) -- No acceleration in X direction.
        posY = posY + (blob.velocity.y * dt) + (0.5 * Constants.GRAVITY * dt * dt)

        blob.velocity.y = blob.velocity.y + (Constants.GRAVITY * dt)

        blob:moveTo(posX, posY)
    end

    -- Time to delete the head blob?
    if self.blobs[1] then
        if self.blobs[1].lifetime < 0 then
            local shape = table.remove(self.blobs, 1)
            self.collider:remove(shape)
        end
    end

    -- Update particles.
    self.particles:update(dt)
end

function Beer:draw()
    -- TODO: debugging
    love.graphics.setColor(255, 0, 255, 255)
    for _, blob in ipairs(self.blobs) do
        local x, y = blob:center()
        love.graphics.circle("fill", x, y, Constants.BEER_BLOB_RADIUS)
    end
    love.graphics.setColor(255, 255, 255, 255)

    local colorMode = love.graphics.getColorMode()
    local blendMode = love.graphics.getBlendMode()
    love.graphics.setColorMode("modulate")
    love.graphics.setBlendMode("additive")
    love.graphics.draw(self.particles, 0, 0)
    love.graphics.setColorMode(colorMode)
    love.graphics.setBlendMode(blendMode)
end

return Beer
