-- character.lua
-- Handle character creation

local assets = require('src.assets')
local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')

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
  local dim = geometry.TileDimensionable:new(1, 2)
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
local function move(sprite, mov, dx, dy)
  if dx == 0 and dy == 0 then
    mov.x, mov.y = 0, 0
    sprite.animating = false
  else
    mov.x = dx * SPEED
    mov.y = dy * SPEED
    sprite.animating = true

    if dx > 0 then
      sprite:setAnimation(SPRITE_LAYERS.RIGHT)
    elseif dx < 0 then
      sprite:setAnimation(SPRITE_LAYERS.LEFT)
    elseif dy > 0 then
      sprite:setAnimation(SPRITE_LAYERS.DOWN)
    else
      sprite:setAnimation(SPRITE_LAYERS.UP)
    end
  end
end

return {
  createCharacter = createCharacter,
  move = move
}
