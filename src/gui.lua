-- gui.lua
--
-- In charge of drawing and taking inputs for the gui
local geometry = require('src.geometry')

--------------------------------------------------------------------------------
--- Wrapper around a GUI entity to provide GUI actions
local Wrapper = {}
local MetaWrapper = {}

--------------------------------------------------------------------------------
--- Create a new wrapper around an entity
--
-- @param system A GUI system
-- @param entity The entity to wrap
--
-- @return A new wrapper
function Wrapper:new(system, entity)
  local wrapper = {
    system = system,
    entity = entity
  }
  setmetatable(wrapper, MetaWrapper)
  return wrapper
end

--------------------------------------------------------------------------------
--- Focus the current entity
function Wrapper:focus()
  self.system.focusedEntity = self.entity
end

--------------------------------------------------------------------------------
--- Check whether the GUI element has focus or not
--
-- @return true if it is focused, false otherwise
function Wrapper:hasFocus()
  return self.system.focusedEntity == self.entity
end

MetaWrapper.__index = Wrapper

--------------------------------------------------------------------------------
--- Component for defining a GUI Widget
local Element = {
  TYPE = "guielement"
}

--------------------------------------------------------------------------------
--- Most of the job is done here
local noop = function () end

--------------------------------------------------------------------------------
--- Create a new GUI element
--
-- @param options.draw      A function that takes a wrapper and a canvas as
--                          parameter and that draws on it
-- @param options.onClick   [optional] Function run when there have been a mouse
--                          click on the element. Takes a wrapper as argument
-- @param options.onKeyDown [optional] Function run where there have been a key
--                          pressed when the component is focused. Takes
--                          a wrapper and a key code as input
--
-- @return A new GUI element
function Element:new(options)
  local element = {
    type = self.TYPE,
    draw = options.draw,
    onClick = options.onClick or noop,
    onKeyDown = options.onKeyDown or noop,
  }
  return element
end

--------------------------------------------------------------------------------
--- System in charge of handling the GUI
local System = {}
local MetaSystem = {}

--------------------------------------------------------------------------------
--- Create a new GUI system
--
-- @param world The ECS world
--
-- @return A new GUI system
function System:new(world)
  local system = {
    world = world,
    focusedEntity = nil
  }
  setmetatable(system, MetaSystem)
  return system
end

--------------------------------------------------------------------------------
--- Draw the gui
--
-- @param canvas The canvas to draw on
function System:render(canvas)
  for entity, guiElement in self.world:getEntitiesWithComponent(Element.TYPE) do
    local pos = self.world:getEntityComponents(entity, geometry.Positionable.TYPE)
    guiElement.draw(
      Wrapper:new(self, entity),
      canvas:translate(pos.x, pos.y)
    )
  end
end

--------------------------------------------------------------------------------
--- React on mouse click
--
-- @param x Mouse X
-- @param y Mouse Y
--
-- @return true if it reacted, false otherwise
function System:onClick(x, y)
  for entity, guiElement in self.world:getEntitiesWithComponent(Element.TYPE) do
    local pos, size = self.world:getEntityComponents(
      entity,
      geometry.Positionable.TYPE,
      geometry.Dimensionable.TYPE
    )

    local dx, dy = x - pos.x, y - pos.y

    self.focusedEntity = nil
    if 0 <= dx and dx <= size.width and 0 <= dy and dy <= size.height then
      guiElement.onClick(Wrapper:new(self, entity))
      return true
    end
    return false
  end
end

--------------------------------------------------------------------------------
--- React on a key down
--
-- @param key Key code
--
-- @return true if it reacted, false otherwise
function System:onKeyDown(key)
  if self.focusedEntity then
    local guiElement = self.world:getEntityComponents(
      self.focusedEntity,
      Element.TYPE
    )

    if guiElement then
      guiElement.onKeyDown(Wrapper:new(self, self.focusedEntity), key)
    end
  end
  return false
end

MetaSystem.__index = System

return {
  Element = Element,
  System = System
}
