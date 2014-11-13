-- collision.lua
-- Handle objects collisions

local combat = require('src.game.combat')
local character = require('src.game.character')
local geometry = require('src.geometry')

--------------------------------------------------------------------------------
--- Return true if the rectangles overlaps
local function rectangleCollides(x1, y1, w1, h1, x2, y2, w2, h2)
  local r1, d1 = x1 + w1, y1 + h1
  local r2, d2 = x2 + w2, y2 + h2
  return x2 <= r1 and x1 <= r2 and y2 <= d1 and y1 <= d2
end

--------------------------------------------------------------------------------
--- Handle collisions between objects
local function applyCollisions(world, tileIndex)
  for entity, harmful in world:getEntitiesWithComponent(combat.Harmful.TYPE) do
    local harmPos, harmDim = world:getEntityComponents(
      entity,
      geometry.TilePositionable.TYPE,
      geometry.TileDimensionable.TYPE
    )
    for charEntity, charComp in world:getEntitiesWithComponent(character.Character.TYPE) do
      local charPos, charDim = world:getEntityComponents(
        charEntity,
        geometry.TilePositionable.TYPE,
        geometry.TileDimensionable.TYPE
      )

      if rectangleCollides(harmPos.x, harmPos.y, harmDim.w, harmDim.h,
                           charPos.x, charPos.y, charDim.w, charDim.h) then
        harmful:hit(charEntity, charComp)
        if charComp.health <= 0 then
          world:removeEntity(charEntity)
          tileIndex:removeEntity(
            charEntity,
            math.floor(charPos.x), math.floor(charPos.y)
          )
        end
      end
    end
  end
end

return {
  applyCollisions = applyCollisions
}
