-- biome.lua
--
-- Modelisation of the overworld biomes

local tileutils = require('src.generation.models.tileutils')
local object = require('src.generation.models.object')

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
    tileMask = tileutils.TileMask:new(),
    objects = {}
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
-- This function has a bad complexity
function Biome:removeTiles(...)
  self.tileMask:remove(...)

  tileList = self.tileMask:toList()
end

--------------------------------------------------------------------------------
--- Distance of a given point to the biome
function Biome:distanceTo(x, y)
  local distance = ((x - self.center.x)^2 + (y - self.center.y)^2)
  distance = distance / self.codeSpace:getComplexity()
  return distance
end

function Biome:addObject(tiles, layer, rng)
  local object = object.Object:new(tiles, self.z, layer)
  -- search for an origin
  local tilesToRemove = nil
  local origin = nil

  local permutation = rng:randomPermutation(#self.tileList)

  for _, randomIndex in ipairs(permutation) do
    origin = self.tileList[randomIndex]
    tilesToRemove = self.tileMask:match(origin, tiles)
    if tilesToRemove ~= nil then
      break
    end
  end

  if tilesToRemove ~= nil then
    object.origin = origin
    self:removeTiles(unpack(tilesToRemove))
    table.insert(self.objects, object)
  end
end

function Biome:createObjects(rng)
  for _ = 1,10 do
    self:addObject(object.TilePatterns.SmallSquare, 1, rng)
    self:addObject(object.TilePatterns.Character, 2, rng)
    self:addObject(object.TilePatterns.House, 1, rng)
  end
end

function Biome:createObjectEntities(world, tileIndex)
  for _, o in ipairs(self.objects) do
    o:createEntities(world, tileIndex)
  end
end

MetaBiome.__index = Biome

return {
  TileMask = TileMask,
  Biome = Biome
}