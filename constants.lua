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
Constants.GRAVITY = 750 -- 750 pixels/sec^2, where 32 pixels ~ 1 meter

-- Player constants.
Constants.PLAYER_SPEED = 175 -- 175 pixels/sec
Constants.PLAYER_JUMP = 400 -- instantaneous Y velocity of 400 pixels/sec
Constants.PLAYER_DRUNK_DRAIN_RATE = 3 -- Lose 3 drunk points/sec.
Constants.PLAYER_REACH = 20 -- Punches 20 pixels away.
Constants.PLAYER_PUNCH_DAMAGE = 40 -- 20 HP damage per punch.
Constants.PLAYER_DRINK_POINTS = 10 -- Number of drunk points to add for every drink.

-- Pubmate constants.
Constants.PUBMATE_DRUNK_DRAIN_RATE_MIN = 2 -- Lose 2 drunk points/sec.
Constants.PUBMATE_DRUNK_DRAIN_RATE_MAX = 4 -- Lose 4 drunk points/sec.
Constants.PUBMATE_PUNCH_DAMAGE_MIN = 10 -- 10 HP damage per punch.
Constants.PUBMATE_PUNCH_DAMAGE_MAX = 30 -- 30 HP damage per punch.
Constants.PUBMATE_PUNCH_COOLDOWN = 2 -- 2 seconds between punches.

-- Bro constants.
Constants.BRO_PUNCH_DAMAGE_MIN = 10 -- 10 HP damage per punch.
Constants.BRO_PUNCH_DAMAGE_MAX = 30 -- 30 HP damage per punch.
Constants.BRO_PUNCH_COOLDOWN = 2 -- 2 seconds between punches.

-- Beer constants.
Constants.BEER_COOLDOWN = 0.15 -- 0.15 seconds per beer blob
Constants.BEER_BLOB_POINTS = 2 -- Each beer blob replenishes 2 drunk points.
Constants.BEER_BLOB_RADIUS = 15 -- Radius of individual beer blobs.
Constants.BEER_BLOB_LIFETIME = 1 -- 1 second.
Constants.BEER_BLOB_SPEED = 400 -- Speed of new blobs.

-- Flamethrower constants.
Constants.FIRE_COOLDOWN = 0.15 -- 0.15 seconds per fire blob
Constants.FIRE_BLOB_DAMAGE = 2 -- Each fire blob damage 2 hit points.
Constants.FIRE_BLOB_RADIUS = 15 -- Radius of individual fire blobs.
Constants.FIRE_BLOB_LIFETIME = 0.3 -- 1 second.
Constants.FIRE_BLOB_SPEED = 500 -- Speed of new blobs.

return Constants
