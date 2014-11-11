-- movement.lua
-- Movement handling
local geometry = require('src.geometry')

--------------------------------------------------------------------------------
--- Component for entities that can have a velocity in a tile set
local TileMovable = {
  TYPE = "tilemovable"
}

--------------------------------------------------------------------------------
--- Create a new movable component
function TileMovable:new()
  return {
    type = self.TYPE,
    x = 0,
    y = 0
  }
end

--------------------------------------------------------------------------------
--- Update movable components to set their new positions
--
-- Update tile index at the same time
--
function updateTileMovable(world, dt)
  for entity, mov in world:getEntitiesWithComponent(TileMovable.TYPE) do
    if mov.x ~= 0 or mov.y ~= 0 then
      local pos = world:getEntityComponents(entity, geometry.TilePositionable.TYPE)
      pos:setX(pos.x + mov.x * dt)
      pos:setY(pos.y + mov.y * dt)
    end
  end
end

return {
  TileMovable = TileMovable,
  updateTileMovable = updateTileMovable
}
