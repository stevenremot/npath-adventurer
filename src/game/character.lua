-- character.lua
-- Handle character creation

local assets = require('src.assets')
local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')

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
  local mov = movement.TileMovable:new()

  world:addComponent(character, pos)
  world:addComponent(character, dim)
  world:addComponent(character, render)
  world:addComponent(character, mov)
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

local SPEED = 5

--------------------------------------------------------------------------------
--- Movement functions for a character
local function moveLeft(sprite, mov)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.LEFT)
  mov.x = -SPEED
  mov.y = 0
end
local function moveRight(sprite, mov)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.RIGHT)
  mov.x = SPEED
  mov.y = 0
end
local function moveUp(sprite, mov)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.UP)
  mov.y = -SPEED
  mov.x = 0
end
local function moveDown(sprite, mov)
  sprite.animating = true
  sprite:setAnimation(SPRITE_LAYERS.DOWN)
  mov.y = SPEED
  mov.x = 0
end
local function stop(sprite, mov)
  sprite.animating = false
  mov.y = 0
  mov.x = 0
end

return {
  createCharacter = createCharacter,
  moveLeft = moveLeft,
  moveRight = moveRight,
  moveUp = moveUp,
  moveDown = moveDown,
  stop = stop
}
