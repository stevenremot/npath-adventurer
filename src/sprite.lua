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
--
-- @return A new sprite resource
function SpriteResource:new(image, width, height, animNumbers, stepNumbers)
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
    height = height
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
    currentStep = 1
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

return {
  SpriteResource = SpriteResource,
  Sprite = Sprite
}
