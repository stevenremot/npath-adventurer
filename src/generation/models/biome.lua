-- biome.lua
--
-- Modelisation of the overworld biomes

local tileutils = require('src.generation.models.tileutils')
local object = require('src.generation.models.object')
local Types = require('src.world').Tile.TYPE

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

function Biome:addObject(object, rng)
  -- search for an origin
  local tiles = object.tileList
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
  for _, codeUnit in ipairs(self.codeSpace.components) do
    if codeUnit:isCodespace() then
      self:addObject(
        object.House:new(self.z, rng:randomi(4,7), rng:randomi(3,5)),
        rng
      )
    elseif codeUnit:isFunction() then
      self:addObject(
        object.House:new(self.z, rng:randomi(3,4), rng:randomi(3,4)),
        rng
      )
    elseif codeUnit:isValue() then
      for _ = 1,rng:randomi(3,10) do
        local name = "blue"
        if self.type ~= Types.PLAIN and self.type ~= Types.VILLAGE then
          name = "red"
        end
        self:addObject(object.Character:new(self.z, name), rng)
      end
    end
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