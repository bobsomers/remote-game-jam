local Vector = require "hump.vector"

local Constants = {}

-- Game info.
Constants.TITLE = "Fight Pub"
Constants.AUTHOR = "Team BetaCorp: Bob Somers, Chris Gibson, and Paul Morales"

-- Screen dimensions.
Constants.SCREEN = Vector(960, 540)
Constants.CENTER = Constants.SCREEN / 2

-- Debug mode.
Constants.DEBUG_MODE = true

-- World constants.
Constants.GRAVITY = 300 -- 300 pixels/sec^2, where 32 pixels ~ 1 meter

-- Player constants.
Constants.PLAYER_SPEED = 160 -- 160 pixels/sec

return Constants
