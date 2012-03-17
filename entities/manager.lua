local Class = require "hump.class"

local EntityManager = Class(function(self)
    self.entities = {}
    self.shapeIndex = {}
end)

function EntityManager:register(entity)
    -- Add the entity to our list of entities and shape index (if it has a
    -- shape).
    table.insert(self.entities, entity)
    if entity.shape then
        self.shapeIndex[entity.shape] = entity
    end
end

function EntityManager:reset()
    -- Reset all entities that are registered.
    for i, entity in ipairs(self.entities) do
        entity:reset()
    end
end

-- Returns nil of no entity with that shape was found.
function EntityManager:findByShape(shape)
    return self.shapeIndex[shape]
end

function EntityManager:update(dt)
    -- Update all entities we manage.
    for i, entity in ipairs(self.entities) do
        entity:update(dt)
    end
end

function EntityManager:draw()
    -- Update all entities we manage.
    for i, entity in ipairs(self.entities) do
        entity:draw()
    end
end

return EntityManager
