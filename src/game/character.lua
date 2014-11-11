-- character.lua
-- Handle character creation

local assets = require('src.assets')
local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite = require('src.sprite')

local CHARACTER_WIDTH, CHARACTER_HEIGHT = 40, 80

--------------------------------------------------------------------------------
--- Create a new character entity
--
-- @param world      The ECS world
-- @param spriteName The sprite name
-- @param x
-- @param y
-- @param tileIndex
local function createCharacter(world, spriteName, x, y, z, tileIndex)
  local spriteObj = assets.createSprite(spriteName)

  local character = world:createEntity()
  local pos = geometry.TilePositionable:new(x, y, z, 2)
  local dim = geometry.TileDimensionable:new(CHARACTER_WIDTH, CHARACTER_HEIGHT)
  local render = graphics.Renderable:new(
    function (canvas)
      canvas:drawImage{ image = spriteObj, x = 0, y = 0 }
    end
  )
  local spriteComp = sprite.SpriteComponent:new(spriteObj)

  world:addComponent(character, pos)
  world:addComponent(character, dim)
  world:addComponent(character, render)
  world:addComponent(character, spriteComp)

  tileIndex:register(character, pos)

  return character
end

return {
  createCharacter = createCharacter
}
