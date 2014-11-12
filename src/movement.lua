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
local function getGroundHeight(x, y, world, tileIndex)
  for _, entity in ipairs(tileIndex:getEntitiesAtPoint(x, y)) do
    local pos = world:getEntityComponents(
      entity,
      geometry.TilePositionable.TYPE
    )
    if pos.layer == 0 then
      return pos.z
    end
  end
  return nil
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

      local halfSize = size.h / 2
      local checkX, checkY = newX, newY + halfSize

      local maxZ = 0
      local hasVoid = false

      for i = 0,1 do
        for j = 0,1 do
          local height = getGroundHeight(
            checkX + i * size.w, checkY + j * halfSize,
            world, tileIndex
          )

          if height == nil then
            hasVoid = true
          elseif height > maxZ then
            maxZ = height
          end
        end
      end

      if not hasVoid and pos.z >= maxZ then
        pos:setX(newX)
        pos:setY(newY)
        pos.z = maxZ
      end
    end
  end
end

return {
  TileMovable = TileMovable,
  updateTileMovable = updateTileMovable
}
