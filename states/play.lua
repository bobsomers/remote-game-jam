local Gamestate = require "hump.gamestate"

local PlayState = Gamestate.new()

function PlayState:init()
    self:reset()
end

function PlayState:reset()
    -- TODO
end

function PlayState:update(dt)
    -- TODO
end

function PlayState:draw()
    -- TODO
    love.graphics.print("Hello play state!", 400, 300)
end

return PlayState
