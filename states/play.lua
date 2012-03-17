local Gamestate = require "hump.gamestate"
local MapLoader = require "AdvTiledLoader.Loader"

local PlayState = Gamestate.new()

function PlayState:init()
    MapLoader.path = "maps/"
    self.map = MapLoader.load("test.tmx")

    -- Reset transient game state.
    self:reset()
end

function PlayState:reset()
    -- TODO
end

function PlayState:update(dt)
    -- TODO
end

function PlayState:draw()
    self.map:draw()
end

return PlayState
