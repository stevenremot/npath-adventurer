-- ecs.lua
--
-- Base structure for entity-component-system architecture

--------------------------------------------------------------------------------
--- Database of association between entities and components
local World = {}
local MetaWorld = {}

--------------------------------------------------------------------------------
--- Create a new world
--
-- @return A new world
function World:new()
   local world = {
      components = {},
      currentEntityNumber = 0,
      freeEntities = {}
   }

   setmetatable(world, MetaWorld)
   return world
end

--------------------------------------------------------------------------------
--- Create a new entity
--
-- @return A new entity
function World:createEntity()
   if #self.freeEntities > 0 then
      return table.remove(self.freeEntities)
   else
      self.currentEntityNumber = self.currentEntityNumber + 1
      return self.currentEntityNumber
   end
end

--------------------------------------------------------------------------------
--- Associate a component to an entity
--
-- @param entity    An entity created with createEntity
-- @param component A component. It must have a type field
function World:addComponent(entity, component)
   if not self.components[component.type] then
      self.components[component.type] = {}
   end
   self.components[component.type][entity] = component
end

--------------------------------------------------------------------------------
--- Remove an entity.
--
-- @param entity THe entity to remove from the world
function World:removeEntity(entity)
   table.insert(self.freeEntities, entity)

   for type, tab in pairs(self.components) do
      tab[entity] = nil
   end
end

--------------------------------------------------------------------------------
--- Return true if the entity has a component of the right type associated
--
-- @param entity        The entity to test
-- @param componentType The componnt type to test
--
-- @return true if there is a component of type componentType associated to
--         the entity, false otherwise
function World:hasComponent(entity, componentType)
   return self.components[componentType][entity] ~= nil
end

--------------------------------------------------------------------------------
--- Get the components associated to the entity
--
-- Be careful : It does not check if components exists
--
-- @param entity An entity created with createEntity
-- @param ...    The component types to retrieve
--
-- @return The components as multiple values
function World:getEntityComponents(entity, ...)
   local components = {}
   for _, type in ipairs{...} do
      table.insert(components, self.components[type][entity])
   end
   return unpack(components)
end

--------------------------------------------------------------------------------
-- Return an iterator on the entities that have a component of a specific type
--
-- @param type The type of the components to retrieve
--
-- @return Iterator of entity, component
function World:getEntitiesWithComponent(type)
   return pairs(self.components[type])
end

MetaWorld.__index = World

return {
   World = World
}
