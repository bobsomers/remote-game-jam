local Constants = require "constants"

function love.conf(t)
    -- Game info.
    t.title = "Fight Pub"
    t.author = "Team BetaCorp: Bob Somers, Chris Gibson, and Paul Morales"

    -- Graphic settings.
    t.screen.width = Constants.SCREEN.x
    t.screen.height = Constants.SCREEN.y

    -- Show console on Windows?
    t.console = Constants.DEBUG_MODE
end
