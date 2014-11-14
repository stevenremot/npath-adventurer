-- overworld.lua
--
-- Creation of the overworld biomes based on the segmented codespaces
local world = require('src.world')
local random = require('src.generation.random')

local Biome = require('src.generation.models.biome').Biome
local Transition = require('src.generation.models.transition').Transition
local TransitionSegment = require('src.generation.models.transition').TransitionSegment

--------------------------------------------------------------------------------
--- The overworld is a rectangle with the given size (in tile units)
local OverworldSize = {
  w = 400,
  h = 400
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
  { 2, 2 },
  { 4, 1 } 
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

    table.insert(biomes, Biome:new(
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
  if transitions[biome1] ~= nil then
    if transitions[biome1][biome2] ~= nil then
      return transitions[biome1][biome2]
    end
  end

  if transitions[biome2] ~= nil then
    if transitions[biome2][biome1] ~= nil then
      return transitions[biome2][biome1]
    end
  end

  if transitions[biome1] == nil then
    transitions[biome1] = {}
  end
  transitions[biome1][biome2] = Transition:new(biome1, biome2)
  return transitions[biome1][biome2]
end

local function createTransitions(biomes, biomeTiles)
  local transitions = {}

  -- vertical transitions
  for j = 1, OverworldSize.h do
    for i = 1, OverworldSize.w-1 do
      local biome1, biome2 = biomeTiles[i][j], biomeTiles[i+1][j]
      local z1, z2 = biomes[biome1].z, biomes[biome2].z
      if biome1 ~= biome2 then
        if z1 ~= z2 then
          local t = getTransition(transitions, biome1, biome2)
          local s = TransitionSegment:new(
            {i+1, j},
            {i+1, j+1},
            z1,
            z2
          )
          t:addSegment(s)
        end
      end
    end
  end

  -- horizontal transitions
  for i = 1, OverworldSize.w do
    for j = 1, OverworldSize.h-1 do
      local biome1, biome2 = biomeTiles[i][j], biomeTiles[i][j+1]
      local z1, z2 = biomes[biome1].z, biomes[biome2].z
      if biome1 ~= biome2 then
        if z1 ~= z2 then
          local t = getTransition(transitions, biome1, biome2)
          local s = TransitionSegment:new(
            {i, j+1},
            {i+1, j+1},
            z1,
            z2
          )
          t:addSegment(s)
        end
      end
    end
  end

  return transitions
end

local function createTransitionEntities(ecsWorld, tileIndex, transitions)
  for _, line in pairs(transitions) do
    for _, t in pairs(line) do
      t:createCorners()
      t:createEntities(ecsWorld, tileIndex)
      t:createStairs(ecsWorld, tileIndex)
    end
  end
end

--------------------------------------------------------------------------------
--- Generate the overworld map
-- @param codespace list
-- @return "overworld" world.Map
local function generateOverworld(codespaces, ecsWorld, tileIndex)
  -- fixed seed for testing purposes
  local rng = random.Rng:new(os.time())

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
  createTransitionEntities(ecsWorld, tileIndex, transitions)
  
  local map = world.Map:new({tiles = tiles})
  map:toEntities(ecsWorld, tileIndex)

  for _, b in ipairs(biomes) do
    b:createObjects(rng); b:createObjectEntities(ecsWorld, tileIndex)
  end

  return map
end


return {
  OverworldSize = OverworldSize,
  generateOverworld = generateOverworld
}
