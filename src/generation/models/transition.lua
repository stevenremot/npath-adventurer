-- transition.lua
--
-- Modelisation of the transitions between biomes
local assets = require('src.assets')

local function tileEquality(tile1, tile2)
  return tile1[1] == tile2[1] and tile1[2] == tile2[2]
end

local function tileSum(tile1, tile2)
  return { tile1[1] + tile2[1], tile1[2] + tile2[2] }
end

local function tileSub(tile1, tile2)
  return { tile1[1] - tile2[1], tile1[2] - tile2[2] }
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
    z2 = z2,
    startCorner = nil,
    endCorner = nil
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

function TransitionSegment:getDirection()
  if self.endPoint[1] == self.startPoint[1] then
    return {0, 1}
  elseif self.startPoint[2] == self.endPoint[2] then
    return {1, 0}
  else
    print('invalid direction')
    return nil
  end       
end

-- @return Segment of length 1 with the same startPoint and direction as self
function TransitionSegment:getStartSubSegment()
  local newEnd = tileSum(self.startPoint, self:getDirection())
  return TransitionSegment:new(
    self.startPoint,
    newEnd,
    self.z1,
    self.z2
  )
end

-- @return Segment of length 1 with the same endPoint and direction as self
function TransitionSegment:getEndSubSegment()
  local newStart = tileSub(self.endPoint, self:getDirection())
  return TransitionSegment:new(
    newStart,
    self.endPoint,
    self.z1,
    self.z2
  )
end

function TransitionSegment:isOrthogonal(other)
  local stype = self:getType()
  local otype = other:getType()

  if stype == 'leftright' or stype == 'rightleft' then
    if otype == 'updown' or otype == 'downup' then
      return true
    end
  end

  if otype == 'leftright' or otype == 'rightleft' then
    if stype == 'updown' or stype == 'downup' then
      return true
    end
  end

  return false
end

function TransitionSegment:createEntities(world, tileIndex)  
  local type = self:getType()
  local heightDiff = math.abs(self.z1 - self.z2)
  local borderImage = 'assets/images/'
  local wallImage = 'assets/images/rock.png'

  local dmin, dmax = 0, self:getLength()-1
  if self.startCorner ~= nil then
    dmin = 1
    if tileEquality(self:getDirection(), {1, 0}) then
      self.startCorner:createEntities(world, tileIndex)
    end
  end
  if self.endCorner ~= nil then
    dmax = dmax-1
    if tileEquality(self:getDirection(), {1, 0}) then
      self.endCorner:createEntities(world, tileIndex)
    end
  end

  -- create border
  if type == 'leftright' then
    borderImage = borderImage .. 'border_left.png'
    for dy = dmin, dmax do
      local x = self.startPoint[1]
      local y = self.startPoint[2] + dy
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z2, 1)
    end
  elseif type == 'rightleft' then
    borderImage = borderImage .. 'border_right.png'
    for dy = dmin, dmax do
      local x = self.startPoint[1] - 1
      local y = self.startPoint[2] + dy
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z1, 1)
    end
  elseif type == 'updown' then
    borderImage = borderImage .. 'border_up.png'
    for dx = dmin, dmax do
      local x = self.startPoint[1] + dx
      local y = self.startPoint[2]
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z2, 1)
    end
  elseif type == 'downup' then
    borderImage = borderImage .. 'border_down.png'
    for dx = dmin, dmax do
      local x = self.startPoint[1] + dx
      local y = self.startPoint[2] - 1
      assets.createTileEntity(world, tileIndex, borderImage, x, y, self.z1, 1)
      for dz = 1, heightDiff do
        assets.createTileEntity(world, tileIndex, wallImage, x, y, self.z1 - dz, 1)
      end
    end
  end
end

MetaTransitionSegment.__index = TransitionSegment

local TransitionCorner = {}
local MetaTransitionCorner = {}

function TransitionCorner:new(segment1, segment2)
  local x1 = segment1.startPoint[1] + segment1.endPoint[1]
  local x2 = segment2.startPoint[1] + segment2.endPoint[1]
  if x1 > x2 then
    segment2, segment1 = segment1, segment2
  end

  local transitionCorner = {
    segment1 = segment1,
    segment2 = segment2
  }

  setmetatable(transitionCorner, MetaTransitionCorner)
  return transitionCorner
end

function TransitionCorner:getType()
  local type1 = self.segment1:getType()
  local type2 = self.segment2:getType()

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
  local t = self:getType()
  local cornerImage = 'assets/images/corner_' .. t .. '.png'
  local wallImage = 'assets/images/rock.png'

  local origin = self.segment1.startPoint
  local layer = 1.7
  if t == 'inner_downright' then
    origin = tileSub(origin, {0, 1})
  elseif t == 'outer_downright' or t == 'outer_upright' then
    origin = tileSub(origin, {0, 1})
    layer = 1.3
  elseif t == 'outer_upleft' then
    origin = tileSub(origin, {1, 1})
    layer = 1.3
  elseif t == 'outer_downleft' then
    origin = tileSub(origin, {1, 0})
    layer = 1.3
  end

  local z1, z2 = self.segment1.z1, self.segment1.z2
  if z1 > z2 then
    z1, z2 = z2, z1
  end
  local x, y = origin[1], origin[2]

  assets.createTileEntity(world, tileIndex, cornerImage, x, y, z2, layer)

  if t == 'inner_downright' or t == 'inner_downleft' or t == 'outer_upright' then
    for dz = 1, z2-z1 do
      assets.createTileEntity(world, tileIndex, wallImage, x, y, z2 - dz, 1)
    end
  elseif t == 'outer_upleft' then
    for dz = 1, z2-z1 do
      assets.createTileEntity(world, tileIndex, wallImage, x+1, y, z2 - dz, 1)
    end
  end

end

MetaTransitionCorner.__index = TransitionCorner

-- Attempt to connect another orthogonal TransitionSegment to self
local function findCorner(seg, other)
  if seg:isOrthogonal(other) then   
    local altitudeCond = (seg.z1 == other.z1 and seg.z2 == other.z2)
    altitudeCond = altitudeCond or (seg.z2 == other.z1 and seg.z1 == other.z2)
    if altitudeCond then
      local ss = tileEquality(seg.startPoint, other.startPoint)
      local se = tileEquality(seg.startPoint, other.endPoint)
      local ee = tileEquality(seg.endPoint, other.endPoint)
      local es = tileEquality(seg.endPoint, other.startPoint)
      if ss then
        local corner = TransitionCorner:new(
          seg:getStartSubSegment(),
          other:getStartSubSegment()
        )
        seg.startCorner = corner
        other.startCorner = corner
      elseif se then
        local corner = TransitionCorner:new(
          seg:getStartSubSegment(),
          other:getEndSubSegment()
        )
        seg.startCorner = corner
        other.endCorner = corner
      elseif ee then
        local corner = TransitionCorner:new(
          seg:getEndSubSegment(),
          other:getEndSubSegment()
        )
        seg.endCorner = corner
        other.endCorner = corner
      elseif es then
        local corner = TransitionCorner:new(
          seg:getEndSubSegment(),
          other:getStartSubSegment()
        )
        seg.endCorner = corner
        other.startCorner = corner
      end
    end
  end
end

local Stair = {}
local MetaStair = {}

function Stair:new(origin, width, z1, z2)
  local stair = {
    origin = origin,
    width = width,
    z1 = z1,
    z2 = z2
  }
  setmetatable(stair, MetaStair)
  return stair
end

function Stair:createEntities(world, tileIndex)
  local stairLeft = 'assets/images/stair_side_left.png'
  local stairRight = 'assets/images/stair_side_right.png'
  local stairMiddle = 'assets/images/stair_middle.png'

  local x, y = self.origin[1], self.origin[2]-1
  local height = self.z1 - self.z2

  for dz = 1, height do
    assets.createTileEntity(world, tileIndex, stairLeft, x, y, self.z1 - dz, 2)
  end

  for dx = 1, self.width-2 do
    for dz = 1, height do
      assets.createTileEntity(world, tileIndex, stairMiddle, x+dx, y, self.z1 - dz, 2)
    end
  end

  for dz = 1, height do
    assets.createTileEntity(world, tileIndex, stairRight, x+self.width-1, y, self.z1 - dz, 2)
  end
end

MetaStair.__index = Stair

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

function Transition:createCorners()
  for _, s in ipairs(self.segments) do
    -- horizontal segment
    if tileEquality(s:getDirection(), {1, 0}) then
      for _, s2 in ipairs(self.segments) do
        if s.startCorner == nil or s.endCorner == nil then
          findCorner(s, s2)
        end
      end
    end
  end
end

function Transition:createStairs(world, tileIndex)
  for _, s in ipairs(self.segments) do
    if s:getType() == 'downup' and s:getLength() > 3 then
      local origin = tileSum(s.startPoint, {1, 0})
      local width = s:getLength() - 2
      local stair = Stair:new(
        origin,
        width,
        s.z1,
        s.z2
      )
      stair:createEntities(world, tileIndex)
    end
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
