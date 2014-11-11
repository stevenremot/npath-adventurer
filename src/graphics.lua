-- graphics.lua
--
-- Abstraction layer on top of love
local geometry = require("src.geometry")



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
--- Set the font size
--
-- @param size
function Canvas:setFontSize(size)
  love.graphics.setFont(love.graphics.newFont(size * self.ratio.y))
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
-- @param options.color  {r, g, b }
-- @param options.x
-- @param options.y
-- @param options.size
-- @param options.width  Optional, the width of the box containing the text.
--                       The text will be wrapped to fit in it.
-- @param options.anchor "left", "center" or "right"
--
-- @return self
function Canvas:drawText(options)
  local color = options.color
  love.graphics.setColor(color.r, color.g, color.b)
  local x, y = self:canvasToScreen(options.x, options.y)

  self:setFontSize(options.size or 20)
  if options.width then
    local screenWidth = options.width * self.ratio.x
    love.graphics.printf(options.text, x, y, screenWidth, options.anchor or "left")
  else
    love.graphics.print(options.text, x, y)
  end

  return self
end

--------------------------------------------------------------------------------
--- Draw an image on the screen
--
-- @param options.image
-- @param options.x
-- @param options.y
--
-- @return self
function Canvas:drawImage(options)
  local x, y = self:canvasToScreen(options.x, options.y)
  love.graphics.draw(options.image, x, y, 0, self.ratio.x, self.ratio.y)
  return self
end

--------------------------------------------------------------------------------
--- Draw a rectangle on the screen
--
-- @param options.x
-- @param options.y
-- @param options.width
-- @param options.height
-- @param options.fillColor [optional]
-- @param options.strokeColor [optional]
--
-- @return self
function Canvas:drawRectangle(options)
  local x, y = self:canvasToScreen(options.x, options.y)
  local w, h = options.width * self.ratio.x, options.height * self.ratio.y

  if options.fillColor then
    local color = options.fillColor
    love.graphics.setColor(color.r, color.g, color.b)
    love.graphics.rectangle("fill", x, y, w, h)
  end

  if options.strokeColor then
    local color = options.strokeColor
    love.graphics.setColor(color.r, color.g, color.b)
    love.graphics.rectangle("line", x, y, w, h)
  end

  return self
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
--- Render the positionable entities on a canvas
--- This should be used to render GUI elements
--
-- @param world  ECS world
-- @param canvas Canvas to draw one
local function render(world, canvas)
  for entity, renderable in world:getEntitiesWithComponent(Renderable.TYPE) do
    if world:hasComponent(entity, geometry.Positionable.TYPE) then
      local positionable = world:getEntityComponents(
        entity,
        geometry.Positionable.TYPE
      )
      renderable.draw(canvas:translate(positionable.x, positionable.y))
    elseif not world:hasComponent(entity, geometry.TilePositionable.TYPE) then
      renderable.draw(canvas)
    end
  end
end

--------------------------------------------------------------------------------
--- Viewport object to render constrained parts of the world
local Viewport = {}
local MetaViewport = {}

--------------------------------------------------------------------------------
--- Create a new viewport
--
-- @param x
-- @param y
-- @param w
-- @param h
function Viewport:new(x, y, w, h)
  local viewport = {
    x = x,
    y = y,
    w = w,
    h = h
  }
  setmetatable(viewport, MetaViewport)
  return viewport
end

--------------------------------------------------------------------------------
--- Check if an entity with tileposition x, y and dimensions w, h intersects the
--- viewport
function Viewport:intersects(x, y, w, h)
  return x + w > self.x and x < self.x + self.w and y + h > self.y and y < self.y + self.h
end

function Viewport:translate(dx, dy)
  self.x = self.x + dx
  self.y = self.y + dy
end

MetaViewport.__index = Viewport

--------------------------------------------------------------------------------
--- Index to quickly retrieve tile entities
local TileIndex = {}
local MetaTileIndex = {}

--------------------------------------------------------------------------------
--- Create a new index
--
-- @return A new index
function TileIndex:new()
  local index = {
    index = {}
  }
  setmetatable(index, MetaTileIndex)
  return index
end

--------------------------------------------------------------------------------
--- Add an entity to the index
--
-- @param entity
-- @param pos    Its TilePositionable component
function TileIndex:register(entity, pos)
  local x, y = pos.x, pos.y

  self:indexEntity(entity, math.floor(x), math.floor(y))
end

--------------------------------------------------------------------------------
--- Index an entity to a position
--
-- @param entity
-- @param x      integer
-- @param y      integer
function TileIndex:indexEntity(entity, x, y)
  if not self.index[x] then
    self.index[x] = {}
  end

  if not self.index[x][y] then
    self.index[x][y] = { entity }
  else
    local i = self.index[x][y]
    i[#i+1] = entity
  end
end

--------------------------------------------------------------------------------
--- Get entities to draw on viewport
--
-- @param world
-- @param viewport
--
-- @return A list of { entity = entity, tile = TIlePositonable, render = Renderable }
function TileIndex:getEntitiesInViewport(world, viewport)
  local entitiesToDraw = {}

  local left = math.floor(viewport.x) - 1
  local right = math.ceil(viewport.x + viewport.w)
  local up = math.floor(viewport.y) - 1
  local down = math.ceil(viewport.y + viewport.h)

  for x = left, right do
    if self.index[x] then
      for y = up, down do
        if self.index[x][y] then
          for _, entity in ipairs(self.index[x][y]) do
            local pos, renderable = world:getEntityComponents(
              entity, geometry.TilePositionable.TYPE, Renderable.TYPE
            )
            entitiesToDraw[#entitiesToDraw+1] = {
              entity = entity,
              tile = pos,
              render = renderable
            }
          end
        end
      end
    end
  end

  return entitiesToDraw
end

MetaTileIndex.__index = TileIndex

--------------------------------------------------------------------------------
--- Compare tile by their drawing order
--
-- @param a
-- @param b
local function compareTilesLayer(a, b)
  return a.tile.z < b.tile.z and a.tile.layer < b.tile.layer
end

--------------------------------------------------------------------------------
--- System for rendering tile
local TileRenderSystem = {}
local MetaTileRenderSystem = {}

--------------------------------------------------------------------------------
--- Create a new tile render system
--
-- @param world Ecs world
--
-- @param world The ECS World
function TileRenderSystem:new(world)
  local system = {
    world = world,
    index = TileIndex:new(),
  }
  setmetatable(system, MetaTileRenderSystem)
  return system
end

--------------------------------------------------------------------------------
--- Draw entities on the canvas for a certain viewport
--
-- @param canvas
-- @param viewport
function TileRenderSystem:render(canvas, viewport)
  local entitiesToDraw = self.index:getEntitiesInViewport(self.world, viewport)

  if #entitiesToDraw > 0 then
    table.sort(entitiesToDraw, compareTilesLayer)
    for _, e in ipairs(entitiesToDraw) do
      local x = (e.tile.x - viewport.x) * geometry.TileSize
      local y = (e.tile.y - viewport.y) * geometry.TileSize
      e.render.draw(canvas:translate(x, y))
    end
  end
end

MetaTileRenderSystem.__index = TileRenderSystem

return {
  Canvas = Canvas,
  Renderable = Renderable,
  render = render,
  TileRenderSystem = TileRenderSystem,
  Viewport = Viewport
}
