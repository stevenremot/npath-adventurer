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
  return biomes[nearestBiomes[1][1]], nearestBiomes[1][1]
end

--------------------------------------------------------------------------------
--- Create the models.Biome objects based on the codespaces
local function initBiomes(codespaces, rng)
  local biomes = {}

  local biomeSquareNumber = math.sqrt(#codespaces) - math.sqrt(#codespaces)%1
  biomeSquareNumber = biomeSquareNumber + 1
  local biomeSquareDims = {
    w = OverworldSize.w / biomeSquareNumber,
    h = OverworldSize.h / biomeSquareNumber
  }

  local permutations = {}
  for i = 1, biomeSquareNumber do
    for j = 1, biomeSquareNumber do
      table.insert(permutations, {i,j})
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

  return biomes
end

local function getTransition(transitions, biome1, biome2)
  local t1 = transitions[biome1]
  if t1 ~= nil then
    local t12 = transitions[biome1][biomes2]
    if t12 ~= nil then
      return t12
    end
  end

  local t2 = transitions[biome2]
  if t2 ~= nil then
    local t21 = transitions[biome2][biome1]
    if t21 ~= nil then
      return t21
    end
  end

  transitions[biome1] = {}
  transitions[biome1][biome2] = models.Transition:new(biome1, biome2)
  return transitions[biome1][biome2]
end

local function createTransitions(biomes, biomeTiles)
  local transitions = {}

  -- vertical transitions
  for i = 1, OverworldSize.w-1, 2 do
    for j = 1, OverworldSize.w do
      biome1 = biomeTiles[i][j]
      biome2 = biomeTiles[i+1][j]
      if biome1 ~= biome2 then
        if biomes[biome1].z ~= biomes[biome2].z then
          print(biome1, biome2)
          local t = getTransition(transitions, biome1, biome2)
          local s = models.TransitionSegment:new(
            {i+1, j},
            {i+1, j+1},
            biome1,
            biome2
          )
          t:addSegment(s)
        end
      end
    end  
  end

  -- horizontal transitions
  for i = 1, OverworldSize.w do
    for j = 1, OverworldSize.w-1, 2 do
      biome1 = biomeTiles[i][j]
      biome2 = biomeTiles[i][j+1]
      if biome1 ~= biome2 then
        if biomes[biome1].z ~= biomes[biome2].z then
          print(biome1, biome2)
          local t = getTransition(transitions, biome1, biome2)
          local s = models.TransitionSegment:new(
            {i, j+1},
            {i+1, j+1},
            biome1,
            biome2
          )
          t:addSegment(s)
        end
      end
    end  
  end

  return transitions
end

--------------------------------------------------------------------------------
--- Generate the overworld map
-- @param codespace list
-- @return "overworld" world.Map
local function generateOverworld(codespaces)
  -- fixed seed for testing purposes
  local rng = random.Rng:new(1)

  local biomes = initBiomes(codespaces, rng)

  local tiles = {}
  local biomeTiles = {}
  for i = 1, OverworldSize.w do
    tiles[i] = {}
    biomeTiles[i] = {}
    for j = 1, OverworldSize.h do
      local biome, biomeIndex = findNearestBiome(i, j, biomes)
      biome:addTiles({i, j})
      tiles[i][j] = world.Tile:new({type = biome.type, altitude = biome.z})
      biomeTiles[i][j] = biomeIndex
    end
  end

  local transitions = createTransitions(biomes, biomeTiles)

  local map = world.Map:new({tiles = tiles})
  return map
end


return {
  OverworldSize = OverworldSize,
  generateOverworld = generateOverworld
}
