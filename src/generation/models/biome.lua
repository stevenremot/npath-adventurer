-- biome.lua
--
-- Modelisation of the overworld biomes

local tileutils = require('src.generation.models.tileutils')

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
    tileMask = tileutils.TileMask:new()
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

  for i = #self.tileList, 1, -1 do
    if not self.tileMask:contains(tileList[i]) then
      table.remove(self.tileList, i)
    end
  end
end

--------------------------------------------------------------------------------
--- Distance of a given point to the biome
function Biome:distanceTo(x, y)
  local distance = ((x - self.center.x)^2 + (y - self.center.y)^2)
  distance = distance / self.codeSpace:getComplexity()
  return distance
end

MetaBiome.__index = Biome

return {
  TileMask = TileMask,
  Biome = Biome
}