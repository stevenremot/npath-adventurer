-- object.lua
--
-- Modelisation of an object which populates a biome
local tileutils = require('src.generation.models.tileutils')
local assets = require('src.assets')
local character = require('src.game.character')

local function rect(upleft, downright)
  local r = {}
  local xmin, ymin = upleft[1], upleft[2]
  local xmax, ymax = downright[1], downright[2]
  for i = xmin, xmax do
    for j = ymin, ymax do
      r[#r+1] = {i, j}
    end
  end
  return r
end

local Object = {}
local MetaObject = {}

--- Create a new object
-- tileMask TileMask of this object
-- z Base altitude of this object (typically the altitude of its biome)
-- layer Layer of this object
function Object:new(tileList, z, layer)
  local object = {
    origin = {0, 0},
    tileList = tileList,
    z = z,
    layer = layer or 1
  }
  setmetatable(object, MetaObject)
  return object
end

-- abstract object for testing purposes
function Object:createEntities(world, tileIndex)
  local image = 'assets/images/rock.png'

  for _, tile in ipairs(self.tileList) do
    local x, y = self.origin[1] + tile[1], self.origin[2] + tile[2]
    assets.createTileEntity(world, tileIndex, image, x, y, self.z, self.layer)
  end
end

MetaObject.__index = Object

local House = {}
local MetaHouse = {}

function House:new(z, width, height)
  local width = width or 3
  local height = height or 3
  local house = Object:new(rect({0,0}, {width-1, height-1}), z, 1)
  setmetatable(house, MetaHouse)

  return house
end

function House:createEntities(world, tileIndex)
  local wallImage = 'assets/images/house_wall.png'
  local doorImage = 'assets/images/house_door.png'
  local roofImage = 'assets/images/house_roof.png'

  local upleft, downright = self.tileList[1], self.tileList[#self.tileList]
  local width, height = downright[1] - upleft[1], downright[2] - upleft[2]

  local origin = self.origin
  local x, y = origin[1], origin[2] + height - 1
  local doorX = math.floor(width/2)
  local z = self.z + height

  for dx = 0, width do
    --roof
    assets.createTileEntity(world, tileIndex, roofImage, x+dx, y, z, self.layer)
    for dz = 1, height do
      if dx == doorX then
        if dz == height then
          assets.createTileEntity(world, tileIndex, doorImage, x+dx, y-1, z-dz, self.layer)
        elseif dz < height-1 then
          assets.createTileEntity(world, tileIndex, wallImage, x+dx, y, z-dz, self.layer)
        end
      else
        assets.createTileEntity(world, tileIndex, wallImage, x+dx, y, z-dz, self.layer)
      end
    end
  end 
end

setmetatable(House, { __index = Object })
MetaHouse.__index = House

local Character = {}
local MetaCharacter = {}

function Character:new(z, name)
  local character = Object:new({{0,0}, {0,1}}, z)
  character.name = name

  setmetatable(character, MetaCharacter)
  return character
end

function Character:createEntities(world, tileIndex)
  local x, y = self.origin[1], self.origin[2]
  local group = nil
  if self.name == 'red' then
    group = 'baddies'
  else
    group = 'hero'
  end
  print(self.name, group)
  character.createCharacter(world, self.name, x, y, tileIndex, 10, group)  
end

setmetatable(Character, { __index = Object })
MetaCharacter.__index = Character

return {
  Object = Object,
  House = House,
  Character = Character,
  rect = rect
}