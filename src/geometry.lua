-- geometry.lua
--
-- 2d space routines

--------------------------------------------------------------------------------
--- Component for entities that have a 2d position
local Positionable = {
  TYPE = "positionable"
}

--------------------------------------------------------------------------------
--- Create a new positionable component
--
-- @param x
-- @param y
--
-- @return A new positionable component
function Positionable:new(x, y)
  local component = {
    type = self.TYPE,
    x = x,
    y = y
  }
  return component
end

--------------------------------------------------------------------------------
--- Constant defining our tile space
local TileSize = 40

--------------------------------------------------------------------------------
--- Component for entities that have a 2d position in a tile space
local TilePositionable = {
  TYPE = "tilepositionable"
}

--------------------------------------------------------------------------------
--- Create a new tilepositionable component
--
-- @param x
-- @param y
-- @param z
-- @param layer
--
-- @return A new positionable component
function TilePositionable:new(x, y, z, layer)
  local component = {
    type = self.TYPE,
    x = x,
    y = y,
    z = z,
    layer = layer
  }
  return component
end

--------------------------------------------------------------------------------
--- Component for entities that have a 2d position
local TileDimensionable = {
  TYPE = "tiledimensionable"
}

--------------------------------------------------------------------------------
--- Create a new positionable component
--
-- @param w
-- @param h
--
-- @return A new positionable component
function TileDimensionable:new(w, h)
  local component = {
    type = self.TYPE,
    w = w,
    h = h
  }
  return component
end


return {
  Positionable = Positionable,
  TilePositionable = TilePositionable,
  TileDimensionable = TileDimensionable,
  TileSize = TileSize
}
