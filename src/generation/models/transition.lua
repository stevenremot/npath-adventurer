-- transition.lua
--
-- Modelisation of the transitions between biomes
local assets = require('src.assets')

local function tileEquality(tile1, tile2)
  return tile1[1] == tile2[1] and tile1[2] == tile2[2]
end

--------------------------------------------------------------------------------
--- A biome transition segment
local TransitionSegment = {}
local MetaTransitionSegment = {}

--------------------------------------------------------------------------------
--- Create a transition segment
-- vertical segment: Oriented from left to right, left altitude z1, right altitude z2
-- horizontal segment: Oriented from up to down, up altitude z1, down altitude z2
function TransitionSegment:new(startPoint, endPoint, z1, z2)
  local transitionSegment = {
    startPoint = startPoint,
    endPoint = endPoint,
    z1 = z1,
    z2 = z2
  }

  setmetatable(transitionSegment, MetaTransitionSegment)
  return transitionSegment
end

--- Attempt to merge another TransitionSegment to self
-- @return True if the segments could be merged, false otherwise
function TransitionSegment:merge(other)
  if self.z1 == other.z1 and self.z2 == other.z2 then
    if self:getType() == other:getType() then
      if tileEquality(self.startPoint, other.endPoint) then
        self.startPoint = other.startPoint
        return true
      elseif tileEquality(self.endPoint, other.startPoint) then
        self.endPoint = other.endPoint
        return true
      end
    end
  end

  return false
end

function TransitionSegment:getLength()
  return math.max(
    self.endPoint[1] - self.startPoint[1],
    self.endPoint[2] - self.startPoint[2]
  )
end

function TransitionSegment:getType()
  if self.startPoint[1] == self.endPoint[1] then
    if self.z1 < self.z2 then
      return 'leftright'
    else
      return 'rightleft'
    end
  elseif self.startPoint[2] == self.endPoint[2] then
    if self.z1 < self.z2 then
      return 'updown'
    else
      return 'downup'
    end
  else
    print('error: segment shoud be horizontal or vertical')
  end
end

function TransitionSegment:createEntities(world, tileIndex)
  local type = self:getType()
  local heightDiff = math.abs(self.z1 - self.z2)
  local borderImage = 'assets/images/'
  local wallImage = 'assets/images/rock.png'

  -- create border
  if type == 'leftright' then
    borderImage = borderImage .. 'border_left.png'
    for dy = 0, self:getLength()-1 do
      local x = self.startPoint[1]
      local y = self.startPoint[2] + dy
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z2, 1)
    end
  elseif type == 'rightleft' then
    borderImage = borderImage .. 'border_right.png'
    for dy = 0, self:getLength()-1 do
      local x = self.startPoint[1] - 1
      local y = self.startPoint[2] + dy
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z1, 1)
    end
  elseif type == 'updown' then
    borderImage = borderImage .. 'border_up.png'
    for dx = 0, self:getLength()-1 do
      local x = self.startPoint[1] + dx
      local y = self.startPoint[2]
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z2, 1)
    end
  elseif type == 'downup' then
    borderImage = borderImage .. 'border_down.png'
    for dx = 0, self:getLength()-1 do
      local x = self.startPoint[1] + dx
      local y = self.startPoint[2] - 1
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z1, 1)
      for dz = 1, 2*heightDiff do
        assets.createTileEntity(world, tileIndex, wallImage, x, y+dz, self.z2, 1)
      end
    end
  end
end

MetaTransitionSegment.__index = TransitionSegment

local TransitionCorner = {}
local MetaTransitionCorner = {}

function TransitionCorner:new(segment1, segment2)
  local transitionCorner = {
    segment1 = segment1,
    segment2 = segment2
  }

  setmetatable(transitionCorner, MetaTransitionCorner)
  return transitionCorner
end

function TransitionCorner:getType()
  local type1 = segment1:getType()
  local type2 = segment2:getType()

  if type1 == 'updown' and type2 == 'leftright' then
    return 'outer_downright'
  elseif type1 == 'updown' and type2 == 'rightleft' then
    return 'inner_upright'
  elseif type1 == 'downup' and type2 == 'leftright' then
    return 'outer_upright'
  elseif type1 == 'downup' and type2 == 'rightleft' then
    return 'inner_downright'
  elseif type1 == 'leftright' and type2 == 'updown' then
    return 'inner_upleft'
  elseif type1 == 'leftright' and type2 == 'downup' then
    return 'inner_downleft'
  elseif type1 == 'rightleft' and type2 == 'updown' then
    return 'outer_downleft'
  elseif type1 == 'rightleft' and type2 == 'downup' then
    return 'outer_upleft'
  end
end

function TransitionCorner:createEntities(world, tileIndex)

end

MetaTransitionCorner.__index = TransitionCorner


local Transition = {}
local MetaTransition = {}

--- Transition between the biomes of index biome1 and biome2
function Transition:new(biome1, biome2)
  local transition = {
    biome1 = biome1,
    biome2 = biome2,
    segments = {}    
  }

  setmetatable(transition, MetaTransition)
  return transition
end

function Transition:addSegment(segment)
  local merged = false

  for _, s in ipairs(self.segments) do
    if s:merge(segment) then
      merged = true
      break
    end
  end

  if not merged then
    table.insert(self.segments, segment)
  end
end

--- Create ecs entities
-- @param world Ecs world
function Transition:createEntities(world, tileIndex)
  for _, s in ipairs(self.segments) do
    s:createEntities(world, tileIndex)
  end
end

MetaTransition.__index = Transition

return {
  Transition = Transition,
  TransitionSegment = TransitionSegment
}