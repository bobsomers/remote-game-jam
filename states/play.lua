local Gamestate = require "hump.gamestate"
local Vector = require "hump.vector"
local MapLoader = require "AdvTiledLoader.Loader"
local Collider = require "hardoncollider"
local EntityManager = require "entities.manager"
local Constants = require "constants"
local Player = require "entities.player"
local PubMate = require "entities.pubmate"
local Bro = require "entities.bro"
local DrunkCam = require "entities.drunkcam"
local AnAL = require "AnAL.AnAL"
local Crosshair = require "fx.crosshair"

local PlayState = Gamestate.new()

function PlayState:init()
    -- Set up the collision detection engine.
    self.collider = Collider(100, function(dt, shape1, shape2, mtvX, mtvY)
        -- Just forwards to self instance through closure.
        self:collide(dt, shape1, shape2, mtvX, mtvY)
    end)

    -- Load the tile map and set up solid tiles.
    MapLoader.path = "maps/"
    self.map = MapLoader.load("level1_beta1.tmx")

    -- Setup passive collision shapes for tiles in the collidable layer.
    self:setupTileCollisions("world")
    
    -- Setup passive collision shapes for tiles in the pub-trigger and the bonus-trigger layers.
    self:setupTileCollisions("pub")
    self:setupTileCollisions("bonus")

    -- Load the entity manager.
    self.entities = EntityManager()

    -- Create the camera.
    self.cam = DrunkCam()
    self.entities:register(self.cam)

    -- Load the player.
    self.player = Player(self.collider, self.cam)
    self.player.shape:moveTo(250, 0)
    self.entities:register(self.player)

    -- Load pubmates
    self.pubmates = {}
    for i=1, 6 do
       self.pubmates[i] = PubMate(self.collider)
       self.pubmates[i].shape:moveTo(20 + i*64, 0)
       self.entities:register(self.pubmates[i])
    end
    
    -- Load bros
    self.bros = {}
    for i=1, 60 do
       self.bros[i] = Bro(self.collider)
       self.bros[i].shape:moveTo(2200 + i*40, 0)
       self.entities:register(self.bros[i])
    end
    
    -- Move the drunk camera.
    self.cam:teleport(Vector(self.player.shape:center()))

    -- Load the crosshair.
    self.crosshair = Crosshair()

    -- Load the background music.
    self.music = love.audio.newSource("sounds/music.mp3", "stream")
    self.music:setVolume(0.5)

    self.score=0
    
end

function PlayState:enter(previous)
    love.mouse.setVisible(false)

    self.lastFpsTime = 0

    -- Reset all entities.
    self.entities:reset()

    -- Play the background music.
    self.music:rewind()
    self.music:play()
end

function PlayState:leave()
    love.mouse.setVisible(true)
end

function PlayState:update(dt)
    dt = math.min(dt, 1/15) -- Minimum 15 FPS.

    -- Update all entities.
    self.entities:update(dt)

    -- Update collision detection.
    self.collider:update(dt)

    -- Keep the camera focused on the player.
    local focusX, focusY = self.player.shape:center()
    self.cam:focus(Vector(focusX, focusY))

    -- Update the crosshair.
    self.crosshair:update(dt)

    -- Update FPS in window title (if DEBUG MODE is on).
    if Constants.DEBUG_MODE then
        self.lastFpsTime = self.lastFpsTime + dt
        if self.lastFpsTime > 1 then
            love.graphics.setCaption(table.concat({
                Constants.TITLE,
                " (",
                love.timer.getFPS(),
                " FPS)"
            }))
            self.lastFpsTime = 0
        end
    end
end

function PlayState:draw()
    self.cam:attach()

    self.map:draw()
    self.entities:draw()

    self.cam:detach()

    self.crosshair:draw()
    
    -- Draw player score
    local playX, playY = self.player.shape:center()
    love.graphics.print(self.score, 10, 10)
    
    if self.player.alive == false then
        love.graphics.print("You got sober. :(", 100, 100)
    end
end

function PlayState:keypressed(key)
    if key == " " or key == "w" then
        self.player:jump()
    elseif key == "e" then
        self.player.drunk = self.player.drunk + Constants.PLAYER_DRINK_POINTS
        --if self.player.drunk > 100 then
        --    self.player.drunk = 100
        --end
    end
end

function PlayState:mousepressed(x, y, button)
    -- Left click does flamethrower.
    if button == "l" then
        self.player.fire.firing = true
        self.player.fire.particles:start()
    end

    -- Right click sprays beer.
    if button == "r" then
        self.player.beer.spraying = true
        self.player.beer.particles:start()
    end
end

function PlayState:mousereleased(x, y, button)
    -- Stop shooting fire.
    if button == "l" then
        self.player.fire.firing = false
        self.player.fire.particles:stop()
    end

    -- Stop spraying beer.
    if button == "r" then
        self.player.beer.spraying = false
        self.player.beer.particles:stop()
    end
end

function PlayState:collide(dt, shape1, shape2, mtvX, mtvY)
    local player, pubmate, bro, world, beer, fire
    local playerIndex, pubmateIndex, broIndex
    
    -- What is shape1?
    if shape1.kind then
        if shape1.kind == "player" then
            player = self.entities:findByShape(shape1)
            playerIndex = 1
        elseif shape1.kind == "pubmate" then
            pubmate = self.entities:findByShape(shape1)
            pubmateIndex = 1
        elseif shape1.kind == "bro" then
            bro = self.entities:findByShape(shape1)
            broIndex = 1
        elseif shape1.kind == "world" then
            world = shape1
        elseif shape1.kind == "pub" then
            pub = shape1
        elseif shape1.kind == "beer" then
            beer = shape1
        elseif shape1.kind == "fire" then
            fire = shape1
        elseif shape1.kind == "bonus" then
            bonus = shape1
        else
            print("Unknown shape kind " .. shape1.kind .. "?")
        end
    else
        print("Shape1 has no kind!")
    end

    -- What is shape2?
    if shape2.kind then
        if shape2.kind == "player" then
            player = self.entities:findByShape(shape2)
            playerIndex = 2
        elseif shape2.kind == "pubmate" then
            pubmate = self.entities:findByShape(shape2)
            pubmateIndex = 2
        elseif shape2.kind == "bro" then
            bro = self.entities:findByShape(shape2)
            broIndex = 2
        elseif shape2.kind == "world" then
            world = shape2
        elseif shape2.kind == "pub" then
            pub = shape2
        elseif shape2.kind == "beer" then
            beer = shape2
        elseif shape2.kind == "fire" then
            fire = shape2
        elseif shape2.kind == "bonus" then
            bonus = shape2
        else
            print("Unknown shape kind " .. shape2.kind .. "?")
        end
    else
        print("Shape2 has no kind!")
    end

    -- Dispatch the appropriate collision resolver.
    if player and world then
        if playerIndex == 2 then
            mtvX = -mtvX
            mtvY = -mtvY
        end
        player:collideWorld(world, Vector(mtvX, mtvY))
    elseif pubmate and world then
        if pubmateIndex == 2 then
            mtvX = -mtvX
            mtvY = -mtvY
        end
        pubmate:collideWorld(world, Vector(mtvX, mtvY))
        pubmate:jump()
    elseif bro and world then
        if broIndex == 2 then
            mtvX = -mtvX
            mtvY = -mtvY
        end
        bro:collideWorld(world, Vector(mtvX, mtvY))
        bro:jump()
    elseif player and pubmate then
        -- Nothing to do.
    elseif player and bro then
        if broIndex == 2 then
            mtvX = -mtvX
            mtvY = -mtvY
        end
        bro:attackPlayer(player, Vector(mtvX, mtvY))
    elseif pubmate and bro then
        -- Random chance as to who attacks who.
        if math.random() < 0.5 then
            if pubmateIndex == 2 then
                mtvX = -mtvX
                mtvY = -mtvY
            end
            pubmate:attackBro(bro, Vector(mtvX, mtvY))
        else
            if broIndex == 2 then
                mtvX = -mtvX
                mtvY = -mtvY
            end
            bro:attackPubmate(pubmate, Vector(mtvX, mtvY))
        end    
    elseif beer and pubmate then
        -- Watering the troops!
        pubmate.drunk = pubmate.drunk + Constants.BEER_BLOB_POINTS
        if pubmate.drunk > 100 then
            pubmate.drunk = 100
        end
        beer.used = true
    elseif fire and bro then
        -- Enemy fire.
        bro.health = bro.health - Constants.FIRE_BLOB_DAMAGE
        if bro.health <= 0 then
            bro:kill()
            self.score = self.score + 10000
        end
        
    elseif fire and pubmate then
        -- Friendly fire.
        pubmate.health = pubmate.health - Constants.FIRE_BLOB_DAMAGE
        if pubmate.health <= 0 then
            pubmate:kill()
        end
    elseif player and bonus then
        self.score = self.score + 10
    elseif pubmate and pub then
        pubmate:kill()
        self.score = self.score + 25000000
    else
        --print("No collision resolver for collision!")
    end
end

function PlayState:setupTileCollisions(layerName)
    local layer = map.tl[layerName]
    if layer == nil then
        print("No tile layer " .. layerName .. "!")
        return
    end
    for x = 1, map.width do
        for y = 1, map.height do
            if layer.tileData[y] then
                local tile = map.tiles[layer.tileData[y][x]]
                if tile then
                    if tile.properties.solid then
                        local shape = self.collider:addRectangle(
                            (x - 1) * 32, (y - 1) * 32,
                            32, 32
                        )
                        shape.kind = layerName
                        self.collider:addToGroup(layerName, shape)
                        self.collider:setPassive(shape)
                    elseif tile.properties.rampUp then
                        local shape = self.collider:addPolygon(
                            (x - 1) * 32, y * 32,
                            x * 32, y * 32,
                            x * 32, (y - 1) * 32
                        )
                        shape.kind = layerName
                        self.collider:addToGroup(layerName, shape)
                        self.collider:setPassive(shape)
                    elseif tile.properties.rampDown then
                        local shape = self.collider:addPolygon(
                            (x - 1) * 32, (y - 1) * 32,
                            (x - 1) * 32, y * 32,
                            x * 32, y * 32
                        )
                        shape.kind = layerName
                        self.collider:addToGroup(layerName, shape)
                        self.collider:setPassive(shape)
                    elseif tile.properties.pub then
                        local shape = self.collider:addRectangle(
                            (x - 1) * 32, (y - 1) * 32,
                            32, 32
                        )
                        shape.kind = layerName
                        self.collider:addToGroup(layerName, shape)
                        self.collider:setPassive(shape)
                    elseif tile.properties.bonus then
                        local shape = self.collider:addRectangle(
                            (x - 1) * 32, (y - 1) * 32,
                            32, 32
                        )
                        shape.kind = layerName
                        self.collider:addToGroup(layerName, shape)
                        self.collider:setPassive(shape)
                    end
                end
            end
        end
    end
end

return PlayState
