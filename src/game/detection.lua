-- detection.lua
-- Detection of nearby entities

local geometry = require('src.geometry')
local movement = require('src.movement')

--------------------------------------------------------------------------------
--- Component for entities that perform actions when entities are near
local Detector = {
  TYPE = "detector"
}

--------------------------------------------------------------------------------
--- Create a new detector component.
--
-- @param layer The layer to react to
-- @param actions A list of arrays {detectDistance, action}. The action is a function
--                that takes an entity and a position component as parameter
function Detector:new(layer, actions)
  table.sort(actions, function (a, b) return a[1] < b[1] end)
  return {
    type = self.TYPE,
    layer = layer,
    actions = actions
  }
end

--------------------------------------------------------------------------------
--- Call a detector for entities that are near it
local function callDetector(detectorEntity, detector, detectorPos, world)
  for entity, _ in world:getEntitiesWithComponent(movement.TileMovable.TYPE) do
    if entity ~= detectorEntity then
      local pos = world:getEntityComponents(entity, geometry.TilePositionable.TYPE)
      local dx, dy = pos.x - detectorPos.x, pos.y - detectorPos.y
      local distance = math.sqrt(dx * dx + dy * dy)

      for _, tab in pairs(detector.actions) do
        if distance < tab[1] then
          tab[2](entity, pos)
          return
        end
      end
    end
  end
end

--------------------------------------------------------------------------------
--- Call detectors for entities that are near them
local function callDetectors(world)
  for entity, detector in world:getEntitiesWithComponent(Detector.TYPE) do
    local pos = world:getEntityComponents(entity, geometry.TilePositionable.TYPE)
    callDetector(entity, detector, pos, world)
  end
end

return {
  Detector = Detector,
  callDetectors = callDetectors
}
