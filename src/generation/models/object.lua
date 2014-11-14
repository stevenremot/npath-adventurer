-- object.lua
--
-- Modelisation of an object which populates a biome
local tileutils = require('src.generation.models.tileutils')
local assets = require('src.assets')

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
    layer = layer
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

local TilePatterns = {
  SmallSquare = {{0,0}, {0,1}, {1,1}, {1,0}},
  Character = {{0,0}, {0,-1}},
  House = {{0,0}, {0,1}, {0,2}, {1,0}, {1,1}, {1,2}, {2,0}, {2,1}, {2,2}}
}

return {
  Object = Object,
  TilePatterns = TilePatterns
}