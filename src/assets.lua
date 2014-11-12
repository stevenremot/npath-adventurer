-- assets.lua
--
-- Utility functions to create entities from assets
--------------------------------------------------------------------------------

local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite   = require('src.graphics.sprite')

--------------------------------------------------------------------------------
local loadedAssets = {
  images = {},
  sprites = {}
}

--------------------------------------------------------------------------------
--- Load an image from the file system
--
-- @param imageDir The path to the image
--
-- @return THe loaded image
local function loadImage(imageDir)
  local image = loadedAssets.images[imageDir]
  if not image then
    image = love.graphics.newImage(imageDir)
    loadedAssets.images[imageDir] = image
  end
  return image
end

--------------------------------------------------------------------------------
--- Create a renderable, tilepositionable and tiledimensionable entity
--- from an image file
local function createTileEntity(world, tileIndex, imageDir, x, y, z, layer)
  local x = x or 0
  local y = y or 0
  local z = z or 0
  local layer = layer or 0

  local entity = world:createEntity()
  local pos = geometry.TilePositionable:new(x, y, z, layer)
  world:addComponent(
    entity,
    pos
  )
  tileIndex:register(entity, pos)
  local image = loadImage(imageDir)

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

--------------------------------------------------------------------------------
--- Create a new sprite resource
local function loadSprite(name, imageDir, width, height, animNumber, stepNumber)
  loadedAssets.sprites[name] = sprite.SpriteResource:new(
    loadImage(imageDir),
    width, height,
    animNumber, stepNumber
  )
end

--------------------------------------------------------------------------------
--- Load all sprites registered in assets
local function loadSprites()
  local sprites = require('assets.sprites')
  for name, spec in pairs(sprites) do
    loadSprite(
      name,
      spec.image,
      spec.width, spec.height,
      spec.animNumber, spec.stepNumber,
      spec.offsetX or 0, spec.offsetY or 0
    )
  end
end

--------------------------------------------------------------------------------
--- Create a new sprite based on a registered resource
local function createSprite(name)
  return sprite.Sprite:new(loadedAssets.sprites[name])
end

return {
  createTileEntity = createTileEntity,
  loadSprites = loadSprites,
  createSprite = createSprite
}
