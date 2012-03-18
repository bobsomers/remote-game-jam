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
    
    -- Setup passive collision shapes for tiles in the pub-trigger layer.
    self:setupTileCollisions("pub")

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
    for i=1, 20 do
       self.pubmates[i] = PubMate(self.collider)
       self.pubmates[i].shape:moveTo(20 + i*64, 0)
       self.entities:register(self.pubmates[i])
    end
    
    -- Load bros
    self.bros = {}
    for i=1, 20 do
       self.bros[i] = Bro(self.collider)
       self.bros[i].shape:moveTo(2000 + i*64, 0)
       self.entities:register(self.bros[i])
    end
    
    -- Move the drunk camera.
    self.cam:teleport(Vector(self.player.shape:center()))

    -- Load the crosshair.
    self.crosshair = Crosshair()

    self.score=0
end

function PlayState:enter(previous)
    love.mouse.setVisible(false)

    self.lastFpsTime = 0

    -- Reset all entities.
    self.entities:reset()
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
end

function PlayState:keypressed(key)
    if key == " " or key == "w" then
        self.player:jump()
    end
end

function PlayState:mousepressed(x, y, button)
    -- Left click does punch.
    if button == "l" then
        local x, y = self.player.shape:center()
        if self.player.facing == "left" then
            x = x - (self.player.SIZE.x / 2) - Constants.PLAYER_REACH
        else
            x = x + (self.player.SIZE.x / 2) + Constants.PLAYER_REACH
        end
        y = y - (self.player.SIZE.y / 4) -- 75% up the player's height
        for _, shape in ipairs(self.collider:shapesAt(x, y)) do
            if shape.kind then
                if shape.kind == "pubmate" then
                    local pubmate = self.entities:findByShape(shape)
                    pubmate.health = pubmate.health - Constants.PLAYER_PUNCH_DAMAGE
                elseif shape.kind == "bro" then
                    local bro = self.entities:findByShape(shape)
                    bro.health = bro.health - Constants.PLAYER_PUNCH_DAMAGE
                end
            end
        end
    end

    -- Right click sprays beer.
    if button == "r" then
        self.player.beer.spraying = true
        self.player.beer.particles:start()
    end
end

function PlayState:mousereleased(x, y, button)
    -- Stop spraying beer.
    if button == "r" then
        self.player.beer.spraying = false
        self.player.beer.particles:stop()
    end
end

function PlayState:collide(dt, shape1, shape2, mtvX, mtvY)
    local player, pubmate, bro, world
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
    elseif pubmate and pub then
        pubmate:kill()
        print(self.score)
    else
        print("No collision resolver for collision!")
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
                    end
                end
            end
        end
    end
end

return PlayState
