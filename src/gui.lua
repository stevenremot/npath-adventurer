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
-- @param options.draw       A function that takes a wrapper and a canvas as
--                           parameter and that draws on it
-- @param options.onClick    [optional] Function run when there have been a mouse
--                           click on the element. Takes a wrapper as argument
-- @param options.onKeyDown  [optional] Function run where there have been a key
--                           pressed when the component is focused. Takes
--                           a wrapper and a key code as input
-- @param options.onMouseIn  [optional] Function to run when the mouse cursor is on
--                           the element
-- @param options.onMouseOut [optional] Function to run when the mouse leaves the
--                           element
--
-- @return A new GUI element
function Element:new(options)
  local element = {
    type = self.TYPE,
    draw = options.draw,
    onClick = options.onClick or noop,
    onKeyDown = options.onKeyDown or noop,
    onMouseIn = options.onMouseIn or noop,
    onMouseOut = options.onMouseOut or noop
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
    focusedEntity = nil,
    hoveredEntity = nil
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
--- Return the entity the contains x, y
--
-- @param x
-- @param y
--
-- @return An entity and its gui element or nil
function System:getEntityAtPoint(x, y)
  for entity, guiElement in self.world:getEntitiesWithComponent(Element.TYPE) do
    local pos, size = self.world:getEntityComponents(
      entity,
      geometry.Positionable.TYPE,
      geometry.Dimensionable.TYPE
    )

    local dx, dy = x - pos.x, y - pos.y

    if 0 <= dx and dx <= size.width and 0 <= dy and dy <= size.height then
      return entity, guiElement
    end
  end
  return false
end

--------------------------------------------------------------------------------
--- React on mouse click
--
-- @param x Mouse X
-- @param y Mouse Y
--
-- @return true if it reacted, false otherwise
function System:onClick(x, y)
  local hoveredEntity, guiElement = self:getEntityAtPoint(x, y)
  if hoveredEntity then
    guiElement.onClick(Wrapper:new(self, hoveredEntity))
    return true
  end
  return false
end

--------------------------------------------------------------------------------
--- React on a mouse move
--
-- @param x
-- @param y
function System:onMouseMove(x, y)
  local hoveredEntity, guiElement = self:getEntityAtPoint(x, y)
  if hoveredEntity and hoveredEntity ~= self.hoveredEntity then
    guiElement.onMouseIn(Wrapper:new(hoveredEntity))
  end

  if hoveredEntity ~= self.hoveredEntity then
    local oldGuiElement = self.world:getEntityComponents(
      self.hoveredEntity,
      Element.TYPE
    )
    if oldGuiElement then
      oldGuiElement.onMouseOut(Wrapper:new(self.hoveredEntity))
    end
  end

  self.hoveredEntity = hoveredEntity
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

--------------------------------------------------------------------------------
--- Draw the rectangle of a button
--
-- @param canvas
-- @param width
-- @param height
-- @param strokeColor
-- @param fillColor
local function drawButtonRectangle(canvas, width, height, strokeColor, fillColor)
  canvas:drawRectangle{
    x = 0,
    y = 0,
    width = width,
    height = height,
    strokeColor = strokeColor,
    fillColor = fillColor
  }
end

--------------------------------------------------------------------------------
--- Draw the text of a button
local function drawButtonText(canvas, width, height, text, color, size)
  canvas:drawText{
    x = 5,
    y = (height - size) / 2,
    size = size,
    text = text,
    color = color,
    width = width - 10,
    anchor = "center"
  }
end

--------------------------------------------------------------------------------
--- Create a button
--
-- @param world          The world in which register the button
-- @param options.action Function to run when button is activated
-- @param options.text
-- @param options.x
-- @param options.y
-- @param options.size
-- @param options.width
-- @param options.height
-- @param options.fillColor
-- @param options.strokeColor
--
-- @return The entity that represents the button
local function createButton(world, options)
  local button = world:createEntity()
  local highlight = false
  local width, height = options.width, options.height
  local size = options.size or 20

  local highlightColor = {
    r = math.min(options.fillColor.r * 1.5, 255),
    g = math.min(options.fillColor.g * 1.5, 255),
    b = math.min(options.fillColor.b * 1.5, 255)
  }

  world:addComponent(button, geometry.Positionable:new(options.x, options.y))
  world:addComponent(
    button,
    geometry.Dimensionable:new(width, height)
  )
  world:addComponent(
    button,
    Element:new{
      draw = function (gui, canvas)
        if highlight then
          drawButtonRectangle(
            canvas,
            width, height,
            options.strokeColor, highlightColor
          )
        else
          drawButtonRectangle(
            canvas,
            width, height,
            options.strokeColor, options.fillColor
          )
        end
        drawButtonText(
          canvas, width, height,
          options.text,
          options.strokeColor,
          size
        )
      end,
      onMouseIn = function ()
        highlight = true
      end,
      onMouseOut = function ()
        highlight = false
      end,
      onClick = function ()
        options.action()
      end
    }
  )

  return button
end

return {
  Element = Element,
  System = System,
  createButton = createButton
}
