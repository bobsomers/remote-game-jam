local Class = require "hump.class"
local Vector = require "hump.vector"
local Constants = require "constants"

local Player = Class(function(self)
    self.SIZE = Vector(32, 64)
    self.position = Vector(0, 0)
end)

function Player:update(dt)
    -- TODO
end

function Player:draw()
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("fill",
        self.position.x - (self.SIZE.x / 2), self.position.y - (self.SIZE.y / 2),
        self.SIZE.x, self.SIZE.y
    )
    love.graphics.setColor(255, 255, 255, 255)
end

return Player
