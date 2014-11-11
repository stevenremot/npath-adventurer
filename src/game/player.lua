-- player.Lua
-- Objects related to the main character
local character = require('src.game.character')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')

--------------------------------------------------------------------------------
--- Component to tag an entity as the player
local Player = {
  TYPE = "player"
}

function Player:new()
  return {
    type = self.TYPE
  }
end

local dx = 0
local dy = 0

--------------------------------------------------------------------------------
--- Called when a key has been pressed to move the player
local function onKeyDown(world, key)
  if key == "left" then
    dx = dx - 1
  elseif key == "right" then
    dx = dx + 1
  elseif key == "up" then
    dy = dy - 1
  elseif key == "down" then
    dy = dy + 1
  end

  for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
    local spriteComp, mov = world:getEntityComponents(
      entity,
      sprite.SpriteComponent.TYPE,
      movement.TileMovable.TYPE
    )
    character.move(spriteComp.sprite, mov, dx, dy)
  end
end

--------------------------------------------------------------------------------
--- Called when a key has been released
local function onKeyUp(world, key)
  if key == "left" then
    dx = dx + 1
  elseif key == "right" then
    dx = dx - 1
  elseif key == "up" then
    dy = dy + 1
  elseif key == "down" then
    dy = dy - 1
  end

  for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
    local spriteComp, mov = world:getEntityComponents(
      entity,
      sprite.SpriteComponent.TYPE,
      movement.TileMovable.TYPE
    )
    character.move(spriteComp.sprite, mov, dx, dy)
  end
end

return {
  Player = Player,
  onKeyDown = onKeyDown,
  onKeyUp = onKeyUp
}
