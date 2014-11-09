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
      ratio = {
         x = 0,
         y = 0
      },
      offset = {
         x = 0,
         y = 0
      }
   }
   canvas.ratio.x = canvas.screen.width / canvas.canvas.width
   canvas.ratio.y = canvas.screen.height / canvas.canvas.height

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
   return (x + offset.x) * self.ratio.x,
          (y + offset.y) * self.ratio.y
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
-- @param options.text
-- @param options.color {r, g, b[, a]}
-- @param options.x
-- @param options.y
-- @param options.width Optional, the width of the box containing the text.
--                      The text will be wrapped to fit in it.
function Canvas:drawText(options)
   local color = options.color
   love.graphics.setColor(color.r, color.g, color.b, color.a)
   x, y = self:canvasToScreen(options.x, options.y)

   if options.width then
      local screenWidth = options.width * self.ratio.x
      love.graphics.printf(options.text, x, y, screenWidth)
   else
      love.graphics.print(options.text, x, y)
   end
end

--------------------------------------------------------------------------------
--- Draw an image on the screen
--
-- @param options.image
-- @param options.x
-- @param options.y
function Canvas:drawImage(options)
   local x, y = self:canvasToScreen(options.x, options.y)
   love.graphics.draw(options.image, x, y, 0, self.ratio.x, self.ratio.y)
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
