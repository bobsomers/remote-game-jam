-- Seed the randomness!
math.randomseed(os.time())

local Gamestate = require "hump.gamestate"
local PlayState = require "states.play"

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(PlayState)
end
