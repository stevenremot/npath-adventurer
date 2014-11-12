-- player.Lua
-- Objects related to the main character
local character = require('src.game.character')
local sprite = require('src.graphics.sprite')
local movement = require('src.movement')
local geometry = require('src.geometry')

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

--------------------------------------------------------------------------------
--- Update the player with input state
local function update(world, input)
  for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
    local spriteComp, mov, char = world:getEntityComponents(
      entity,
      sprite.SpriteComponent.TYPE,
      movement.TileMovable.TYPE,
      character.Character.TYPE
    )
    character.move(char, spriteComp.sprite, mov, input.dir.x, input.dir.y)

    if input.attack then
      character.attack(char, spriteComp.sprite, mov, "gummyCharge")
    end
  end
end

--------------------------------------------------------------------------------
--- Center the viewport on the player
--
-- @param world    The ECS world
-- @param viewport
local function centerViewport(world, viewport)
  for entity, _ in world:getEntitiesWithComponent(Player.TYPE) do
    local pos = world:getEntityComponents(entity, geometry.TilePositionable.TYPE)
    viewport:centerOn(pos.x, pos.y)
  end
end

return {
  Player = Player,
  update = update,
  centerViewport = centerViewport
}
