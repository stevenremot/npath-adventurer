-- sprite.lua
--
-- Utlilty functions to handle animated sprites

--------------------------------------------------------------------------------
--- A sprite resource is the raw sprite descriptor. It is common to all objects
--- that share the same sprite
local SpriteResource = {}

--------------------------------------------------------------------------------
--- Create a new sprite resource
--
-- @param image
-- @param width
-- @param height
-- @param animNumbers
-- @param stepNumbers
-- @param offsetX     [optional]
-- @param offsetY     [optional]
--
-- @return A new sprite resource
function SpriteResource:new(image, width, height, animNumbers, stepNumbers, offsetX, offsetY)
  local anims = {}
  local imgW, imgH = image:getDimensions()

  for y = 1,animNumbers do
    local steps = {}
    for x = 1,stepNumbers do
      steps[#steps+1] = love.graphics.newQuad(
        (x-1) * width, (y-1) * height,
        width, height,
        imgW, imgH
      )
    end
    anims[#anims+1] = steps
  end

  return {
    image = image,
    anims = anims,
    width = width,
    height = height,
    offset = {
      x = offsetX or 0,
      y = offsetY or 0
    }
  }
end

--------------------------------------------------------------------------------
--- A sprite is an animated image based on a sprite resource
local Sprite = {}
local MetaSprite = {}

--------------------------------------------------------------------------------
--- Create a new sprite
--
-- @param resource
function Sprite:new(resource)
  local sprite = {
    resource = resource,
    image = resource.image,
    quad = resource.anims[1][1],
    currentAnim = 1,
    currentStep = 1,
    animating = false
  }
  setmetatable(sprite, MetaSprite)
  return sprite
end

--------------------------------------------------------------------------------
--- Set the current sprite animation
--
-- @param anim
function Sprite:setAnimation(anim)
  self.currentAnim = anim
  self.quad = self.resource.anims[anim][self.currentStep]
end

--------------------------------------------------------------------------------
--- Pass to the next animation step
function Sprite:nextStep()
  self.currentStep = self.currentStep % #self.resource.anims[1] + 1
  self.quad = self.resource.anims[self.currentAnim][self.currentStep]
end

MetaSprite.__index = Sprite

--------------------------------------------------------------------------------
--- A simple component to tag entities that have  a sprite as renderable
local SpriteComponent = {
  TYPE = "sprite"
}

function SpriteComponent:new(sprite)
  return {
    type = self.TYPE,
    sprite = sprite
  }
end

local timeIncrement = 0
--------------------------------------------------------------------------------
--- Update all sprites in the world
--
-- @param world
-- @param dt         In seconds
-- @param frameDelay In seconds
local function updateSprites(world, dt, frameDelay)
  timeIncrement = timeIncrement + dt
  local timeToUpdate = 0
  while timeIncrement >= frameDelay do
    timeIncrement = timeIncrement - frameDelay
    timeToUpdate = timeToUpdate + 1
  end

  if timeToUpdate > 0 then
    for entity, sprite in world:getEntitiesWithComponent(SpriteComponent.TYPE) do
      if sprite.sprite.animating then
        for i = 1, timeToUpdate do
          sprite.sprite:nextStep()
        end
      end
    end
  end
end

return {
  SpriteResource = SpriteResource,
  Sprite = Sprite,
  SpriteComponent = SpriteComponent,
  updateSprites = updateSprites
}
