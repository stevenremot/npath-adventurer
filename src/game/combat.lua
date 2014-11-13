-- combat.lua
-- Routines and objects relative to combat system
local geometry = require('src.geometry')

--------------------------------------------------------------------------------
--- A component for describing an entity that does damages
local Harmful = {
  TYPE = "harmful"
}
local MetaHarmful = {}

--------------------------------------------------------------------------------
--- Create a new harmful component
--
-- @param damages
--
-- @return A new harmful component
function Harmful:new(damages, group)
  local harmful = {
    type = self.TYPE,
    damages = damages,
    hitEntities = {},
    group = group
  }
  setmetatable(harmful, MetaHarmful)
  return harmful
end

--------------------------------------------------------------------------------
--- Return true if the entity has already been hit
function Harmful:hasHit(entity)
  return self.hitEntities[entity] ~= nil
end

--------------------------------------------------------------------------------
--- Registered an entity as hit
function Harmful:hit(entity, characterComp)
  if not self:hasHit(entity) and characterComp.group ~= self.group then
    self.hitEntities[entity] = true
    characterComp.health = math.max(characterComp.health - self.damages, 0)
  end
end

MetaHarmful.__index = Harmful

local directions = {
  "down", "right", "left", "up"
}

--------------------------------------------------------------------------------
--- Create the attack box for an attack.
local function createAttackBox(world, spec, characterPos, characterComp)
  local entity = world:createEntity()
  local box = spec.box[directions[characterComp.direction]]

  world:addComponent(
    entity,
    geometry.TilePositionable:new(characterPos.x + box.x, characterPos.y + box.y)
  )
  world:addComponent(
    entity,
    geometry.TileDimensionable:new(box.w, box.h)
  )
  world:addComponent(
    entity,
    Harmful:new(spec.damages, characterComp.group)
  )

  return entity
end

return {
  Harmful = Harmful,
  createAttackBox = createAttackBox
}
