local Gamestate = require "hump.gamestate"
local Vector = require "hump.vector"
local MapLoader = require "AdvTiledLoader.Loader"
local Collider = require "hardoncollider"
local EntityManager = require "entities.manager"
local Constants = require "constants"
local Player = require "entities.player"
local PubMate = require "entities.pubmate"
local Bro = require "entities.bro"

local PlayState = Gamestate.new()

function PlayState:init()
    -- Set up the collision detection engine.
    self.collider = Collider(100, function(dt, shape1, shape2, mtvX, mtvY)
        -- Just forwards to self instance through closure.
        --self:collide(dt, shape1, shape2, mtvX, mtvY)
        print("COLLISION!")
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
    self.player.shape:moveTo(375, 100)
    self.entities:register(self.player)

    -- Reset transient game state.
    self:reset()
end

function PlayState:reset()
    self.lastFpsTime = 0
end

function PlayState:update(dt)
    -- Update all entities.
    self.entities:update(dt)

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
    self.map:draw()
    self.entities:draw()
end

function PlayState:collide(dt, shape1, shape2, mtvX, mtvY)
    -- TODO
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
                        -- TODO
                    elseif tile.properties.rampDown then
                        -- TODO
                    end
                end
            end
        end
    end
end

return PlayState
