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
--- Return true if the position is legal (aka is not underground)
local function canMoveHere(x, y, z, world, tileIndex)
  for _, entity in ipairs(tileIndex:getEntitiesAtPoint(x, y)) do
    local pos = world:getEntityComponents(
      entity,
      geometry.TilePositionable.TYPE
    )
    if pos.layer == 0 then
      return pos.z <= z
    end
  end
  return false
end

--------------------------------------------------------------------------------
--- Update movable components to set their new positions
--
-- Update tile index at the same time
--
local function updateTileMovable(world, dt, tileIndex)
  for entity, mov in world:getEntitiesWithComponent(TileMovable.TYPE) do
    if mov.x ~= 0 or mov.y ~= 0 then
      local pos, size = world:getEntityComponents(
        entity,
        geometry.TilePositionable.TYPE, geometry.TileDimensionable.TYPE
      )

      local newX, newY = pos.x + mov.x * dt, pos.y + mov.y * dt

      local checkX, checkY = newX, newY + size.h
      if mov.x > 0 then
        checkX = checkX + size.w
      end


      if canMoveHere(checkX, checkY, pos.z, world, tileIndex) then
        pos:setX(newX)
        pos:setY(newY)
      end
    end
  end
end

return {
  TileMovable = TileMovable,
  updateTileMovable = updateTileMovable
}
