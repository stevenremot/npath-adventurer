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

local actionsPerKey = {
  left = "moveLeft",
  right = "moveRight",
  down = "moveDown",
  up = "moveUp"
}

--------------------------------------------------------------------------------
--- Called when a key has been pressed to move the player
local function onKeyDown(world, key)
  local action = actionsPerKey[key]

  if action then
    for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
      local spriteComp, mov = world:getEntityComponents(
        entity,
        sprite.SpriteComponent.TYPE,
        movement.TileMovable.TYPE
      )
      character[action](spriteComp.sprite, mov)
    end
  end
end

--------------------------------------------------------------------------------
--- Called when a key has been released
local function onKeyUp(world, key)
  if actionsPerKey[key] then
    for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
      local spriteComp, mov = world:getEntityComponents(
        entity,
        sprite.SpriteComponent.TYPE,
        movement.TileMovable.TYPE
      )
      character.stop(spriteComp.sprite, mov)
    end
  end
end

return {
  Player = Player,
  onKeyDown = onKeyDown,
  onKeyUp = onKeyUp
}
