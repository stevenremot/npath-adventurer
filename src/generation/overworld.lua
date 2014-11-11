-- overworld.lua
--
-- Creation of the overworld biomes based on the segmented codespaces
local world = require('src.world')
local random = require('src.generation.random')

--------------------------------------------------------------------------------
--- The overworld is a rectangle with the given size (in tile units)
local OverworldSize = {
  w = 200,
  h = 200
}

local BiomeTypes = {
  { world.Tile.TYPE.PLAIN, 5},
  { world.Tile.TYPE.VILLAGE, 2},
  { world.Tile.TYPE.FOREST, 3},
  { world.Tile.TYPE.FACTORY, 1}
}
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
function Biome:new(codeSpace, center, type)
  local biome = {
    codeSpace = codeSpace,
    center = center,
    type = type,
    z = 0
  }

  setmetatable(biome, MetaBiome)
  return biome
end

function Biome:distanceTo(x, y)
  local distance = ((x - self.center.x)^2 + (y - self.center.y)^2)
  distance = distance / self.codeSpace:getComplexity()
  return distance
end

MetaBiome.__index = Biome

local function findNearestBiome(i, j, biomes)
  local nearestBiomes = {}
  for n, biome in ipairs(biomes) do
    table.insert(nearestBiomes, { n, biome:distanceTo(i,j) })
  end
  table.sort(nearestBiomes, function (a,b) return a[2] < b[2] end)
  return biomes[nearestBiomes[1][1]]
end

local function initBiomes(codespaces, biomes, rng)

  local biomeSquareNumber = 1 + (math.sqrt(#codespaces)-math.sqrt(#codespaces)%1)
  local biomeSquareDims = {
    w = OverworldSize.w / biomeSquareNumber,
    h = OverworldSize.h / biomeSquareNumber
  }

  local permutations = {}
  for i = 1, biomeSquareNumber do
    for j = 1, biomeSquareNumber do
      table.insert(permutations, {i, j})
    end
  end

  -- create biome centers
  for _, b in ipairs(codespaces) do
    local square, squareIndex = rng:randomListElement(permutations)
    local i, j = square[1], square[2]
    table.remove(permutations, squareIndex)

    local _x = i * biomeSquareDims.w - biomeSquareDims.w / 2
    local _y = j * biomeSquareDims.h - biomeSquareDims.h / 2
    local x = rng:randomf(_x - biomeSquareDims.w/4, _x + biomeSquareDims.w/4)
    local y = rng:randomf(_y - biomeSquareDims.h/4, _y + biomeSquareDims.h/4)

    table.insert(biomes, Biome:new(
        b,
        {x = x, y = y},
        rng:randomDensityListElement(BiomeTypes)
      )
    )
  end

end

--------------------------------------------------------------------------------
--- Generate the overworld map
-- @param codespace list
-- @return "overworld" world.Map
local function generateOverworld(codespaces)
  -- fixed seed for testing purposes
  local rng = random.Rng:new(1)
  local biomes = {}

  initBiomes(codespaces, biomes, rng)

  local tiles = {}
  for i = 1, OverworldSize.w do
    tiles[i] = {}
    for j = 1, OverworldSize.h do
      local biome = findNearestBiome(i, j, biomes)
      tiles[i][j] = world.Tile:new({type = biome.type, altitude = biome.z})
    end
  end

  local map = world.Map:new({tiles = tiles})
  return map
end


return {
  Biome = Biome,
  OverworldSize = OverworldSize,
  TileMask = TileMask,
  generateOverworld = generateOverworld
}
