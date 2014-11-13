-- character.lua
-- Handle character creation

local assets = require('src.assets')
local geometry = require('src.geometry')
local graphics = require('src.graphics.base')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')
local combat = require('src.game.combat')

--------------------------------------------------------------------------------
--- A component for a caracter. A character is basically an entity
--- that con do actions
local Character = {
  TYPE = "character",
  DIRECTION = {
    DOWN = 1,
    RIGHT = 2,
    LEFT = 3,
    UP = 4
  }
}

--------------------------------------------------------------------------------
--- Create a new character component
function Character:new(health, group)
  return {
    type = self.TYPE,
    inAction = false,
    health = health,
    direction = self.DIRECTION.DOWN,
    group = group
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
local function createCharacter(world, spriteName, x, y, tileIndex, health, group)
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
  world:addComponent(character, Character:new(health, group))

  tileIndex:register(character, pos)

  return character
end

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
        character.direction = Character.DIRECTION.RIGHT
      elseif dx < 0 then
        character.direction = Character.DIRECTION.LEFT
      elseif dy > 0 then
        character.direction = Character.DIRECTION.DOWN
      else
        character.direction = Character.DIRECTION.UP
      end
      sprite:setAnimation(character.direction)
    end
  end
end

--------------------------------------------------------------------------------
--- Start an attack
local function attack(world, character, pos, sprite, mov, attackName)
  if not character.inAction then
    character.inAction = true
    local oldMovX, oldMovY = mov.x, mov.y
    local oldResource = sprite.resource
    local oldAnimating = sprite.animating
    local attack = assets.getAttack(attackName)
    sprite:setResource(assets.getSprite(attack.sprite))
    sprite.animating = true
    mov.x, mov.y = 0, 0
    local harmful = combat.createAttackBox(world, attack, pos, character)

    sprite.animEndCallback = function ()
      mov.x, mov.y = oldMovX, oldMovY
      sprite:setResource(oldResource)
      sprite.animating = oldAnimating
      sprite.animEndCallback = nil
      character.inAction = false
      world:removeEntity(harmful)
    end
  end
end

return {
  Character = Character,
  createCharacter = createCharacter,
  move = move,
  attack = attack
}
