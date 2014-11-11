-- overworld.lua
--
-- Creation of the overworld biomes based on the segmented codespaces
local world = require('src.world')
local random = require('src.generation.random')
local models = require('src.generation.models')

--------------------------------------------------------------------------------
--- The overworld is a rectangle with the given size (in tile units)
local OverworldSize = {
  w = 200,
  h = 200
}

--------------------------------------------------------------------------------
--- The biome types and their weights of apparition
local BiomeDistribution = {
  { world.Tile.TYPE.PLAIN, 5 },
  { world.Tile.TYPE.VILLAGE, 2 },
  { world.Tile.TYPE.FOREST, 3 },
  { world.Tile.TYPE.FACTORY, 1 }
}

--------------------------------------------------------------------------------
--- The available altitudes and their weights of apparition
local AltitudeDistribution = {
  { 0, 5 },
  { 1, 2 },
  { 2, 1 }
}

--------------------------------------------------------------------------------
--- Find the nearest biome of the {i,j} tile
-- @param i, j Tile coordinates
-- @param biomes List of the overworld biomes
-- @return Nearest biome
local function findNearestBiome(i, j, biomes)
  local nearestBiomes = {}
  for n, biome in ipairs(biomes) do
    table.insert(nearestBiomes, { n, biome:distanceTo(i,j) })
  end
  table.sort(nearestBiomes, function (a,b) return a[2] < b[2] end)
  return biomes[nearestBiomes[1][1]]
end

--------------------------------------------------------------------------------
--- Create the models.Biome objects based on the codespaces
local function initBiomes(codespaces, biomes, rng)

  local biomeSquareNumber = 1 + math.sqrt(#codespaces)-math.sqrt(#codespaces)%1
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

    table.insert(biomes, models.Biome:new(
        b,
        {x = x, y = y},
        rng:randomDensityListElement(BiomeDistribution),
        rng:randomDensityListElement(AltitudeDistribution)
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
      biome:addTiles({i, j})
      tiles[i][j] = world.Tile:new({type = biome.type, altitude = biome.z})
    end
  end

  local map = world.Map:new({tiles = tiles})
  return map
end


return {
  OverworldSize = OverworldSize,
  generateOverworld = generateOverworld
}
