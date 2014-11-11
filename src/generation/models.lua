-- models.lua
--
-- Modelisation of the overworld biomes and their transitions

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
-- vertical segment: left altitude z1, right altitude z2
-- horizontal segment: up altitude z1, down altitude z2
function TransitionSegment:new(startPoint, endPoint, z1, z2)
  local type = nil
  if startPoint[1] == endPoint[1] then
    type = "vertical"
  elseif startPoint[2] == endPoint[2] then
    type = "horizontal"
  else
    print("Transition segment must be horizontal or vertical")
    return nil
  end

  local transitionSegment = {
    startPoint = startPoint,
    endPoint = endPoint,
    type = type,
    z1 = z1,
    z2 = z2
  }

  setmetatable(transitionSegment, MetaTransitionSegment)
  return transitionSegment
end


return {
  TileMask = TileMask,
  Biome = Biome
}