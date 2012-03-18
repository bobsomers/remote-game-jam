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

local PlayState = Gamestate.new()

function PlayState:init()
    -- Set up the collision detection engine.
    self.collider = Collider(100, function(dt, shape1, shape2, mtvX, mtvY)
        -- Just forwards to self instance through closure.
        self:collide(dt, shape1, shape2, mtvX, mtvY)
    end)

    -- Load the tile map and set up solid tiles.
    MapLoader.path = "maps/"
    self.map = MapLoader.load("test_chris.tmx")

    -- Setup passive collision shapes for tiles in the collidable layer.
    self:setupTileCollisions("world")

    -- Load the entity manager.
    self.entities = EntityManager()

    -- Load the player.
    self.player = Player(self.collider)
    self.player.shape:moveTo(250, 0)
    self.entities:register(self.player)

    -- Load pubmates
    self.pubmates = {}
    for i=1, 5 do
       self.pubmates[i] = PubMate(self.collider)
       self.pubmates[i].shape:moveTo(250 + i*42, 0)
       self.entities:register(self.pubmates[i])
    end
    
    -- Load bros
    self.bros = {}
    for i=1, 5 do
       self.bros[i] = Bro(self.collider)
       self.bros[i].shape:moveTo(1000 + i*42, 0)
       self.entities:register(self.bros[i])
    end
    
    -- Load the drunk camera.
    self.cam = DrunkCam()
    local playerX, playerY = self.player.shape:center()
    self.cam:teleport(Vector(playerX, playerY))
    self.entities:register(self.cam)

    -- Reset transient game state.
    self:reset()
end

function PlayState:reset()
    self.lastFpsTime = 0

    -- Reset all entities.
    self.entities:reset()
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
end

function PlayState:keypressed(key)
    if key == " " or key == "w" then
        self.player:jump()
    end
end

function PlayState:collide(dt, shape1, shape2, mtvX, mtvY)
    local player, pubmate, bro, world
    
    -- What is shape1?
    if shape1.kind then
        if shape1.kind == "player" then
            player = self.entities:findByShape(shape1)
        elseif shape1.kind == "pubmate" then
            pubmate = self.entities:findByShape(shape1)
        elseif shape1.kind == "bro" then
            bro = self.entities:findByShape(shape1)
        elseif shape1.kind == "world" then
            world = shape1
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
        elseif shape2.kind == "pubmate" then
            pubmate = self.entities:findByShape(shape2)
        elseif shape2.kind == "bro" then
            bro = self.entities:findByShape(shape2)
        elseif shape2.kind == "world" then
            world = shape2
        else
            print("Unknown shape kind " .. shape2.kind .. "?")
        end
    else
        print("Shape2 has no kind!")
    end

    -- Dispatch the appropriate collision resolver.
    if player and world then
        player:collideWorld(world, Vector(mtvX, mtvY))
    elseif pubmate and world then
        pubmate:collideWorld(world, Vector(mtvX, mtvY))
        pubmate:jump()
    elseif bro and world then
        bro:collideWorld(world, Vector(mtvX, mtvY))
        bro:jump()
    elseif player and pubmate then
        print("I love you, man!")
    elseif player and bro then
        print("Douchebag!")
    elseif pubmate and bro then
        pubmate:kill()
        print("FFFUUUUUUUUU!!!")
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
                    end
                end
            end
        end
    end
end

return PlayState
