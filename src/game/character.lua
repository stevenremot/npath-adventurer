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

local SPRITE_LAYERS = {
  LEFT = 3,
  RIGHT = 2,
  UP = 4,
  DOWN = 1
}

--------------------------------------------------------------------------------
--- Movement functions for a character
local function moveLeft(sprite)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.LEFT)
end
local function moveRight(sprite)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.RIGHT)
end
local function moveUp(sprite)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.UP)
end
local function moveDown(sprite)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.DOWN)
end
local function stop(sprite)
  sprite.animating = false
end

return {
  createCharacter = createCharacter,
  moveLeft = moveLeft,
  moveRight = moveRight,
  moveUp = moveUp,
  moveDown = moveDown,
  stop = stop
}
