-- models.lua
--
-- Modelisation of the overworld biomes and their transitions
local assets = require('src.assets')

local function tileEquality(tile1, tile2)
  return tile1[1] == tile2[1] and tile1[2] == tile2[2]
end

--------------------------------------------------------------------------------
--- A tilemask is a table indexed with the tiles occupied by an object or
--- an environment
--- It is modelised as a sparse matrix
local TileMask = {}
local MetaTileMask = {}

--------------------------------------------------------------------------------
--- Create a new tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:new(...)
  local tilemask = {}

  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not tilemask[i] then
      tilemask[i] = {}
    end
    tilemask[i][j] = true
  end

  setmetatable(tilemask, MetaTileMask)
  return tilemask
end

--------------------------------------------------------------------------------
--- Add tile index to a tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:add(...)
  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not self[i] then
      self[i] = {}
    end
    self[i][j] = true
  end
end

--------------------------------------------------------------------------------
--- Add a list of tile index to the tilemask
-- @param l Table of tile index: { {i,j}, {k,l}, ... }
function TileMask:addList(l)
  for _, index in ipairs(l) do
    local i, j = index[1], index[2]
    if not self[i] then
      self[i] = {}
    end
    self[i][j] = true
  end
end

--------------------------------------------------------------------------------
--- Remove tile index to a tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:remove(...)
  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not self[i] then
      break
    else
      self[i][j] = nil
      if next(self[i]) == nil then
        self[i] = nil
      end
    end
  end
end


--------------------------------------------------------------------------------
--- Check if the tilemask contains one or several tiles
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
-- @return A boolean
function TileMask:contains(...)
  local b = true

  for _, index in ipairs{...} do
    local i, j = index[1], index[2]

    if not self[i] then
      b = false
      break
    else
      if not self[i][j] then
        b = false
        break
      end
    end

  end

  return b
end

MetaTileMask.__index = TileMask

--------------------------------------------------------------------------------
--- A biome is a part of the overworld generation
local Biome = {}
local MetaBiome = {}

--------------------------------------------------------------------------------
--- Create a new biome
--
-- @param codeSpace CodeSpace associated to this biome
-- @param center { x = x, y = y } Attraction point of the biome
-- @param type of biome
function Biome:new(codeSpace, center, type, z)
  local biome = {
    codeSpace = codeSpace,
    center = center,
    type = type,
    z = z or 0,
    tileList = {},
    tileMask = TileMask:new()
  }

  setmetatable(biome, MetaBiome)
  return biome
end

--------------------------------------------------------------------------------
--- Add a list of tile index
function Biome:addTileList(list)
  for _, tile in ipairs(list) do
    table.insert(self.tileList, tile)
  end
  self.tileMask:addList(list)
end

--------------------------------------------------------------------------------
--- Add one or several tile index
function Biome:addTiles(...)
  for _, tile in ipairs({...}) do
    table.insert(self.tileList, tile)
  end
  self.tileMask:add(...)
end

--------------------------------------------------------------------------------
--- Remove one or several tile index
function Biome:removeTiles(...)
  for _, tile in ipairs({...}) do
    table.remove(self.tileList, tile)
  end
  self.tileMask:remove(...)
end

--------------------------------------------------------------------------------
--- Distance of a given point to the biome
function Biome:distanceTo(x, y)
  local distance = ((x - self.center.x)^2 + (y - self.center.y)^2)
  distance = distance / self.codeSpace:getComplexity()
  return distance
end

MetaBiome.__index = Biome

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
    end
  end
end

MetaTransitionSegment.__index = TransitionSegment


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
  print(#self.segments, self.segments[1]:getLength())  
  for _, s in ipairs(self.segments) do
    s:createEntities(world, tileIndex)
  end
end

MetaTransition.__index = Transition

return {
  TileMask = TileMask,
  Biome = Biome,
  Transition = Transition,
  TransitionSegment = TransitionSegment
}