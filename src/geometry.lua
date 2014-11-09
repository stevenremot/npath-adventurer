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

return {
   Positionable = Positionable
}
