-- tile.lua
-- Define tile management
local geometry = require('src.geometry')
local base = require('src.graphics.base')

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

  local index = self
  pos.setX = function (self, x)
    index:removeEntity(entity, math.floor(self.x), math.floor(self.y))
    self.x = x
    index:indexEntity(entity, math.floor(self.x), math.floor(self.y))
  end

  pos.setY = function (self, x)
    index:removeEntity(entity, math.floor(self.x), math.floor(self.y))
    self.y = y
    index:indexEntity(entity, math.floor(self.x), math.floor(self.y))
  end
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
    self.index[x][y] = {}
  end

  self.index[x][y][entity] = true
end

--------------------------------------------------------------------------------
--- Remove an entity from the index
function TileIndex:removeEntity(entity, x, y)
  self.index[x][y][entity] = nil
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
          for entity, _ in pairs(self.index[x][y]) do
            local pos, renderable = world:getEntityComponents(
              entity, geometry.TilePositionable.TYPE, base.Renderable.TYPE
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
  local az, bz = a.tile.z, b.tile.z
  return az < bz or (az == bz and  a.tile.layer < b.tile.layer)
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
  TileRenderSystem = TileRenderSystem,
  Viewport = Viewport
}
