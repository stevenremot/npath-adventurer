-- graphics.lua
--
-- Abstraction layer on top of love

--------------------------------------------------------------------------------
--- A canvas is an object that handles all drawing operations
local Canvas = {}
local MetaCanvas = {}

--------------------------------------------------------------------------------
--- Create a new canvas
--
-- @param options.screen.width
-- @param options.screen.height
-- @param options.canvas.width
-- @param options.canvas.height
--
-- @¶eturn A new canvas
function Canvas:new(options)
   local canvas = {
      screen = {
         width = options.screen and options.screen.width or 800,
         height = options.screen and options.screen.height or 600
      },
      canvas = {
         width = options.canvas and options.canvas.width or 800,
         height = options.canvas and options.canvas.height or 600
      },
      offset = {
         x = 0,
         y = 0
      }
   }

   setmetatable(canvas, MetaCanvas)
   return canvas
end

--------------------------------------------------------------------------------
--- Convert a position in the canvas to a position in the screen
--
-- @param x
-- @param y
--
-- @return X, Y
function Canvas:canvasToScreen(x, y)
   local offset = self.offset
   local canvas = self.canvas
   local screen = self.screen

   return (x + offset.x) / canvas.width  * screen.width,
          (y + offset.y) / canvas.height * screen.height
end

--------------------------------------------------------------------------------
--- Return a canvas translated from the original
--
-- @param dx
-- @param dy
--
-- @return The translated canvas
function Canvas:translate(dx, dy)
   local canvas = self:new{
      screen = self.screen,
      canvas = self.canvas
   }
   canvas.offset.x = self.offset.x + dx
   canvas.offset.y = self.offset.y + dy
   return canvas
end

--------------------------------------------------------------------------------
--- Draw text on the screen
--
-- @param text
-- @param color {r, g, b[, a]}
-- @param x
-- @param y
-- @param width Optional, the width of the box containing the text. The text will
--              be wrapped to fit in it
function Canvas:drawText(text, color, x, y, width)
   love.graphics.setColor(color.r, color.g, color.b, color.a)
   x, y = self:canvasToScreen(x, y)

   if width then
      local screenWidth = width / self.canvas.width * self.screen.width
      love.graphics.printf(text, x, y, screenWidth)
   else
      love.graphics.print(text, x, y)
   end
end

MetaCanvas.__index = Canvas

--------------------------------------------------------------------------------
--- Component for entities that can be renderer on the screen
local Renderable = {
   TYPE = "renderable"
}

--------------------------------------------------------------------------------
--- Create a new renderable component
--
-- @param draw A function that takes as input a canvas and that operates on it
--
-- @return A new renderable component
function Renderable:new(draw)
   local component = {
      type = self.TYPE,
      draw = draw
   }
   return component
end

--------------------------------------------------------------------------------
--- Render the world on a canvas
--
-- @param world  ECS world
-- @param canvas Canvas to draw one
local function render(world, canvas)
   for _, renderable in world:getEntitiesWithComponent(Renderable.TYPE) do
      renderable.draw(canvas)
   end
end

return {
   Canvas = Canvas,
   Renderable = Renderable,
   render = render
}
