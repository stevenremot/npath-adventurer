-- assets.lua
--
-- Utility functions to create entities from assets
--------------------------------------------------------------------------------

local geometry = require('src.geometry')
local graphics = require('src.graphics')

--------------------------------------------------------------------------------
--- Create a renderable, tilepositionable and tiledimensionable entity
--- from an image file
local function createTileEntity(world, imageDir, x, y, z, layer)
  local x = x or 0
  local y = y or 0
  local z = z or 0
  local layer = layer or 0

  local entity = world:createEntity()
  world:addComponent(
    entity,
    geometry.TilePositionable:new(x, y, z, layer)
  ) 

  local image = love.graphics.newImage(imageDir)
  local w, h = image:getDimensions()
  w = w / geometry.TileSize; h = h / geometry.TileSize;
  world:addComponent(
    entity,
    geometry.TileDimensionable:new(w, h)
  )

  world:addComponent(
    entity,
    graphics.Renderable:new(
      function(canvas)
        canvas:drawImage{
          image = image,
          x = 0,
          y = 0
        }
      end
    )
  )

  return entity

end

return {
    createTileEntity = createTileEntity
  }