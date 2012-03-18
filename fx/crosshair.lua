local Class = require "hump.class"
local Vector = require "hump.vector"

local Crosshair = Class(function(self)
    self.EXTENT = 10
    self.position = Vector(0, 0)
end)

function Crosshair:update(dt)
    self.position.x = love.mouse.getX()
    self.position.y = love.mouse.getY()
end

function Crosshair:draw()
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.line(
        self.position.x - self.EXTENT, self.position.y,
        self.position.x + self.EXTENT, self.position.y
    )
    love.graphics.line(
        self.position.x, self.position.y - self.EXTENT,
        self.position.x, self.position.y + self.EXTENT
    )
    love.graphics.setColor(255, 255, 255, 255)
end

return Crosshair
