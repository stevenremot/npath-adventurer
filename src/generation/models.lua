-- models.lua
--
-- Modelisation of the overworld biomes and their transitions


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
-- vertical segment: Oriented from left to right, left biome biome1, right biome biome2
-- horizontal segment: Oriented from up to down, up biome biome1, down biome biome2
function TransitionSegment:new(startPoint, endPoint, biome1, biome2)
  local transitionSegment = {
    startPoint = startPoint,
    endPoint = endPoint,
    biome1 = biome1,
    biome2 = biome2
  }

  setmetatable(transitionSegment, MetaTransitionSegment)
  return transitionSegment
end

--- Attempt to merge another TransitionSegment to self
-- @return True if the segments could be merged, false otherwise
function TransitionSegment:merge(other)
  if self.biome1 == other.biome1 and self.biome2 == other.biome2 then
    if tileEquality(self.startPoint, other.endPoint) then
      self.startPoint = other.startPoint
      return true
    elseif tileEquality(self.endPoint, other.startPoint) then
      self.endPoint = other.endPoint
      return true
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
    return 'vertical'
  elseif self.startPoint[2] == self.endPoint[2] then
    return 'horizontal'
  else
    print('error: segment shoud be horizontal or vertical')
  end
end

MetaTransitionSegment.__index = TransitionSegment

local function addSegmentInTable(t, segment)
  local merged = false

  for _, s in ipairs(t) do
    if s:merge(segment) then
      merged = true
      break
    end
  end

  if not merged then
    table.insert(t, segment)
  end
end


local Transition = {}
local MetaTransition = {}

--- Transition between the biomes of index biome1 and biome2
function Transition:new(biome1, biome2)
  local transition = {
    biome1 = biome1,
    biome2 = biome2,
    horizontal = {},
    vertical = {}
  }

  setmetatable(transition, MetaTransition)
  return transition
end

function Transition:addSegment(segment)
  if segment:getType() == "vertical" then
    addSegmentInTable(self.vertical, segment)
  elseif segment:getType() == "horizontal" then
    addSegmentInTable(self.horizontal, segment)
  end
end

function Transition:sort()
  table.sort(self.horizontal)
  table.sort(self.vertical)
end

MetaTransition.__index = Transition

return {
  TileMask = TileMask,
  Biome = Biome,
  Transition = Transition,
  TransitionSegment = TransitionSegment
}