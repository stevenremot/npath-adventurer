-- world.lua
--
-- Data structure representing the game world
local assets = require('src.assets')

--------------------------------------------------------------------------------
-- A tile contains information on a map's cell
local Tile = {
  TYPE = {
    PLAIN = "plain",
    VILLAGE = "village",
    DUNGEON = "dungeon",
    FOREST = "forest",
    FACTORY = "factory"
  }
}
local MetaTile = {}

--------------------------------------------------------------------------------
--- Create a new tile
--
-- @param options.type     The type of the tile
-- @param options.altitude The altitude of the tile
-- @param options.link     [optional] The place the user is teleported to when
--                         walking on the tile.
--                         The form is { mapName, x, y }
--
-- @return A new tile
function Tile:new(options)
  local tile = {
    type = options.type,
    altitude = options.altitude,
    link = options.link
  }
  setmetatable(tile, MetaTile)
  return tile
end

--------------------------------------------------------------------------------
--- Convert the tile to lua code
--
-- @return A string
function Tile:serialize()
  local attributes = {
    "type = '"  .. self.type .. "'",
    "altitude = " .. self.altitude
  }

  if self.link then
    table.insert(
      attributes,
      "link = { " ..
        "'" .. self.link[1] .. "', " ..
        self.link[2] .. ", " ..
        self.link[3] ..
        " }"
    )
  end

  return "Tile:new{ " .. table.concat(attributes, ", ") ..  " }"
end

MetaTile.__index = Tile

--------------------------------------------------------------------------------
--- A map represents an area of the world
--
-- It contains a matrix of tiles, and various objects that can have or
-- not a position.
local Map = {}
local MetaMap = {}

--------------------------------------------------------------------------------
--- Create a new map
--
-- @param options.tiles A matrix of tiles
--
-- @return A new map
function Map:new(options)
  local map = {
    tiles = options.tiles
  }
  setmetatable(map, MetaMap)
  return map
end

--------------------------------------------------------------------------------
--- Convert the tiles to lua code
--
-- @return A string
function Map:serializeTiles()
  local lines = {}

  for _, line in ipairs(self.tiles) do
    local tiles = {}
    for _, tile in ipairs(line) do
      table.insert(tiles, tile:serialize())
    end
    table.insert(lines, "{ " .. table.concat(tiles, ", ") .. " }")
  end

  return "{ " .. table.concat(lines, ", ") .. " }"
end

--------------------------------------------------------------------------------
--- Convert the map to lua code
--
-- @return A string
function Map:serialize()
  local s = "Map:new{"
  s = s .. " tiles = " .. self:serializeTiles()
  return s .. " }"
end

--------------------------------------------------------------------------------
--- Create ecs entities from the map's tiles
--
-- @param ecsWorld         Ecs world
-- @param tileRenderSystem
--
-- @return A table of ecs entities
function Map:toEntities(ecsWorld, tileRenderSystem)
  local entities = {}

  for i, line in ipairs(self.tiles) do
    for j, tile in ipairs(line) do
      local entity = assets.createTileEntity(
        ecsWorld,
        tileRenderSystem,
        'assets/images/' .. tile.type .. '.png',
        i,
        j,
        tile.altitude
      )
      table.insert(entities, entity)
    end
  end

  return entities
end




MetaMap.__index = Map

--------------------------------------------------------------------------------
--- A world is a set of named maps
local World = {}
local MetaWorld = {}

--------------------------------------------------------------------------------
--- Create a new world
--
-- @param name The world's name as a string
--
-- @return A new world
function World:new(name)
  local world = {
    name = name,
    maps = {}
  }
  setmetatable(world, MetaWorld)
  return world
end

--------------------------------------------------------------------------------
--- Append a new map to the world
--
-- @param name The name of the map
-- @param map  The Map object
--
-- @return The world
function World:setMap(name, map)
  self.maps[name] = map
  return self
end

--------------------------------------------------------------------------------
--- Find a map by its name
--
-- @param name The name of the map to return
--
-- @return The map named name, or nil if it does not exist
function World:getMap(name)
  return self.maps[name]
end

--------------------------------------------------------------------------------
--- Convert the world to lua code
--
-- @return A string
function World:serialize()
  local s = "World:new('" .. self.name .. "')"

  local maps = {}
  for name, map in pairs(self.maps) do
    table.insert(
      maps,
      ":setMap('" .. name .. "', " .. map:serialize() .. ")"
    )
  end

  return s .. table.concat(maps)
end

MetaWorld.__index = World

--------------------------------------------------------------------------------
--- Save the world in a file
--
-- @param world The world to save
-- @param file  The file in which the world will be saved
--
-- @return true if it succeeded, or false and an error otherwise
local function save(world, file)
  local f, err = io.open(file, "w")

  if not f then
    return false, err
  else
    f:write("return function (Tile, Map, World)\n")
    f:write("  return " .. world:serialize() .. "\nend")
    f:close()
    return true
  end
end

--------------------------------------------------------------------------------
--- Load a world from a file
--
-- @param file The file which contains the world to load
--
-- @return The loaded world, or nil and an error message if it could
--         not load the world
local function load(file)
  local code, err = loadfile(file)

  if not code then
    return nil, err
  else
    local builder = code()
    if type(builder) ~= "function" then
      return nil, "Malformed save file"
    end

    return builder(Tile, Map, World)
  end
end

return {
  Tile = Tile,
  Map = Map,
  World = World,
  save = save,
  load = load
}
