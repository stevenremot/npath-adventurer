-- character.lua
-- Handle character creation

local assets = require('src.assets')
local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')

--------------------------------------------------------------------------------
--- A component for a caracter. A character is basically an entity
--- that con do actions
local Character = {
  TYPE = "character"
}

--------------------------------------------------------------------------------
--- Create a new character component
function Character:new()
  return {
    type = self.TYPE,
    inAction = false
  }
end


--------------------------------------------------------------------------------
--- Create a new character entity
--
-- @param world      The ECS world
-- @param spriteName The sprite name
-- @param x
-- @param y
-- @param tileIndex
local function createCharacter(world, spriteName, x, y, tileIndex)
  local spriteObj = assets.createSprite(spriteName)
  local z = movement.getGroundHeight(x, y, world, tileIndex)

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
  world:addComponent(character, Character:new())

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
local function move(character, sprite, mov, dx, dy)
  if not character.inAction then
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
end

--------------------------------------------------------------------------------
--- Start an attack
local function attack(character, sprite, mov, attackName)
  if not character.inAction then
    character.inAction = true
    local oldMovX, oldMovY = mov.x, mov.y
    local oldResource = sprite.resource
    local oldAnimating = sprite.animating
    sprite:setResource(assets.getSprite(attackName))
    sprite.animating = true
    mov.x, mov.y = 0, 0

    sprite.animEndCallback = function ()
      mov.x, mov.y = oldMovX, oldMovY
      sprite:setResource(oldResource)
      sprite.animating = oldAnimating
      sprite.animEndCallback = nil
      character.inAction = false
    end
  end
end

return {
  Character = Character,
  createCharacter = createCharacter,
  move = move,
  attack = attack
}
